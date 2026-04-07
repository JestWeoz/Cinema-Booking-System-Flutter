import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:cinema_booking_system_app/app/router/app_router.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';

class PaymentDeepLinkService {
  PaymentDeepLinkService._();

  static final PaymentDeepLinkService instance = PaymentDeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  bool _initialized = false;
  String? _lastHandledUri;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleUri(initialUri);
    }

    _subscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (_) {},
    );
  }

  void _handleUri(Uri uri) {
    if (uri.scheme != 'cinema-booking' || uri.host != 'payment-return') {
      return;
    }

    if (_lastHandledUri == uri.toString()) {
      return;
    }
    _lastHandledUri = uri.toString();

    final bookingId = uri.queryParameters['bookingId'];
    if (bookingId == null || bookingId.isEmpty) {
      return;
    }

    final target = Uri(
      path: AppRoutes.paymentResult,
      queryParameters: {
        'bookingId': bookingId,
        if ((uri.queryParameters['bookingCode'] ?? '').isNotEmpty)
          'bookingCode': uri.queryParameters['bookingCode']!,
        if ((uri.queryParameters['status'] ?? '').isNotEmpty)
          'status': uri.queryParameters['status']!,
        if ((uri.queryParameters['responseCode'] ?? '').isNotEmpty)
          'responseCode': uri.queryParameters['responseCode']!,
        if ((uri.queryParameters['transactionId'] ?? '').isNotEmpty)
          'transactionId': uri.queryParameters['transactionId']!,
      },
    ).toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = AppRouter.rootNavigatorKey.currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.popUntil((route) => route.isFirst);
      }
      AppRouter.router.go(target);
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
    _lastHandledUri = null;
  }
}
