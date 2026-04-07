import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/services/payment_launcher.dart';

class BookingPaymentWebViewResult {
  final String bookingId;
  final String? bookingCode;
  final String status;
  final String? responseCode;
  final String? transactionId;

  const BookingPaymentWebViewResult({
    required this.bookingId,
    required this.status,
    this.bookingCode,
    this.responseCode,
    this.transactionId,
  });

  String toRouteLocation() {
    return Uri(
      path: AppRoutes.paymentResult,
      queryParameters: {
        'bookingId': bookingId,
        if ((bookingCode ?? '').isNotEmpty) 'bookingCode': bookingCode!,
        if (status.isNotEmpty) 'status': status,
        if ((responseCode ?? '').isNotEmpty) 'responseCode': responseCode!,
        if ((transactionId ?? '').isNotEmpty) 'transactionId': transactionId!,
      },
    ).toString();
  }
}

class BookingPaymentWebViewPage extends StatefulWidget {
  final String paymentUrl;
  final String bookingId;

  const BookingPaymentWebViewPage({
    super.key,
    required this.paymentUrl,
    required this.bookingId,
  });

  @override
  State<BookingPaymentWebViewPage> createState() =>
      _BookingPaymentWebViewPageState();
}

class _BookingPaymentWebViewPageState extends State<BookingPaymentWebViewPage> {
  late final WebViewController _controller;
  late final Widget _webViewContent;

  final ValueNotifier<int> _progressNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> _pageLoadingNotifier = ValueNotifier<bool>(true);

  Timer? _progressDebounce;
  int _latestProgress = 0;
  int _lastPaintedProgress = 0;
  bool _completed = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
    _webViewContent = RepaintBoundary(
      child: WebViewWidget.fromPlatformCreationParams(
        params: _buildWidgetParams(),
      ),
    );
    unawaited(_controller.loadRequest(Uri.parse(widget.paymentUrl)));
  }

  WebViewController _buildController() {
    late final PlatformWebViewControllerCreationParams params;

    if (!kIsWeb && Platform.isAndroid) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.backgroundDark)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: _onProgress,
          onPageStarted: _onPageStarted,
          onPageFinished: _onPageFinished,
          onWebResourceError: _onWebResourceError,
          onNavigationRequest: _handleNavigation,
        ),
      );

    if (!kIsWeb && Platform.isAndroid) {
      final androidController =
          controller.platform as AndroidWebViewController;
      AndroidWebViewController.enableDebugging(kDebugMode);
      unawaited(androidController.setMediaPlaybackRequiresUserGesture(false));
    }

    return controller;
  }

  PlatformWebViewWidgetCreationParams _buildWidgetParams() {
    final baseParams = PlatformWebViewWidgetCreationParams(
      controller: _controller.platform,
    );

    if (!kIsWeb && Platform.isAndroid) {
      return AndroidWebViewWidgetCreationParams
          .fromPlatformWebViewWidgetCreationParams(
        baseParams,
        // Texture composition keeps scrolling and route transitions lighter
        // than hybrid composition on most Android devices.
        displayWithHybridComposition: false,
      );
    }

    return baseParams;
  }

  void _onProgress(int progress) {
    _latestProgress = progress;
    _progressDebounce?.cancel();
    _progressDebounce = Timer(const Duration(milliseconds: 80), () {
      if (!mounted) return;

      final shouldPaint = (_latestProgress - _lastPaintedProgress).abs() >= 8 ||
          _latestProgress == 100 ||
          _latestProgress == 0;
      if (!shouldPaint) return;

      _lastPaintedProgress = _latestProgress;
      _progressNotifier.value = _latestProgress;
    });
  }

  void _onPageStarted(String _) {
    if (!mounted) return;
    if (_loadError != null) {
      setState(() => _loadError = null);
    }
    _lastPaintedProgress = 0;
    _pageLoadingNotifier.value = true;
    _progressNotifier.value = 0;
  }

  void _onPageFinished(String _) {
    if (!mounted) return;
    _lastPaintedProgress = 100;
    _progressNotifier.value = 100;
    _pageLoadingNotifier.value = false;
  }

  void _onWebResourceError(WebResourceError error) {
    if (!mounted || !_isMainFrameError(error)) return;
    _pageLoadingNotifier.value = false;
    setState(() => _loadError = error.description);
  }

  bool _isMainFrameError(WebResourceError error) {
    final frame = error.isForMainFrame;
    return frame == null || frame;
  }

  FutureOr<NavigationDecision> _handleNavigation(
    NavigationRequest request,
  ) async {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.navigate;

    if (_isBackendReturnUrl(uri)) {
      _completeFromBackendReturn(uri);
      return NavigationDecision.prevent;
    }

    if (_isPaymentReturnDeepLink(uri)) {
      _completeFromDeepLink(uri);
      return NavigationDecision.prevent;
    }

    if (_shouldOpenExternally(uri)) {
      await _openExternalApp(uri.toString());
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  bool _isPaymentReturnDeepLink(Uri uri) {
    return uri.scheme == 'cinema-booking' && uri.host == 'payment-return';
  }

  bool _isBackendReturnUrl(Uri uri) {
    return uri.path.endsWith('/api/v1/payments/vnpay/return') &&
        uri.queryParameters.containsKey('vnp_TxnRef');
  }

  bool _shouldOpenExternally(Uri uri) {
    return uri.scheme.isNotEmpty &&
        uri.scheme != 'http' &&
        uri.scheme != 'https' &&
        uri.scheme != 'about' &&
        uri.scheme != 'data' &&
        uri.scheme != 'javascript' &&
        !_isPaymentReturnDeepLink(uri);
  }

  Future<void> _openExternalApp(String url) async {
    try {
      await PaymentLauncher.open(url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Khong mo duoc ung dung ngoai: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _completeFromDeepLink(Uri uri) {
    _finishWithResult(
      BookingPaymentWebViewResult(
        bookingId: uri.queryParameters['bookingId'] ?? widget.bookingId,
        bookingCode: uri.queryParameters['bookingCode'],
        status: uri.queryParameters['status'] ?? 'PENDING',
        responseCode: uri.queryParameters['responseCode'],
        transactionId: uri.queryParameters['transactionId'],
      ),
    );
  }

  void _completeFromBackendReturn(Uri uri) {
    final responseCode = uri.queryParameters['vnp_ResponseCode'];
    final transactionStatus = uri.queryParameters['vnp_TransactionStatus'];
    _finishWithResult(
      BookingPaymentWebViewResult(
        bookingId: widget.bookingId,
        bookingCode: uri.queryParameters['vnp_TxnRef'],
        responseCode: responseCode,
        transactionId: uri.queryParameters['vnp_TransactionNo'],
        status: _mapReturnStatus(responseCode, transactionStatus),
      ),
    );
  }

  void _finishWithResult(BookingPaymentWebViewResult result) {
    if (_completed) {
      return;
    }
    _completed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop(result);
    });
  }

  String _mapReturnStatus(String? responseCode, String? transactionStatus) {
    if (responseCode == '00' && transactionStatus == '00') {
      return 'SUCCESS';
    }
    if (responseCode == null || responseCode.isEmpty) {
      return 'PENDING';
    }
    return 'FAILED';
  }

  Future<void> _reload() async {
    _lastPaintedProgress = 0;
    _pageLoadingNotifier.value = true;
    _progressNotifier.value = 0;
    setState(() => _loadError = null);
    await _controller.reload();
  }

  @override
  void dispose() {
    _progressDebounce?.cancel();
    _progressNotifier.dispose();
    _pageLoadingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: const Text(
          'Thanh toan VNPay',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _pageLoadingNotifier,
            builder: (_, isLoading, __) {
              if (!isLoading) return const SizedBox.shrink();
              return ValueListenableBuilder<int>(
                valueListenable: _progressNotifier,
                builder: (_, progress, __) {
                  return LinearProgressIndicator(
                    value: progress > 0 && progress < 100
                        ? progress / 100
                        : null,
                    minHeight: 2,
                    backgroundColor: Colors.white10,
                    color: AppColors.primary,
                  );
                },
              );
            },
          ),
          Expanded(
            child: _loadError != null
                ? _PaymentWebViewError(
                    message: _loadError!,
                    onRetry: _reload,
                    onOpenOutside: () => _openExternalApp(widget.paymentUrl),
                  )
                : _webViewContent,
          ),
        ],
      ),
    );
  }
}

class _PaymentWebViewError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onOpenOutside;

  const _PaymentWebViewError({
    required this.message,
    required this.onRetry,
    required this.onOpenOutside,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language_rounded,
              color: Colors.white54,
              size: 52,
            ),
            const SizedBox(height: 16),
            const Text(
              'Khong tai duoc cong thanh toan trong app',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tai lai'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onOpenOutside,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: BorderSide(
                    color: AppColors.secondary.withValues(alpha: 0.35),
                  ),
                ),
                child: const Text('Mo ben ngoai app'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
