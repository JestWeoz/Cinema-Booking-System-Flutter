import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/models/responses/movie_response.dart';

class ReviewAiSummaryResult {
  final String summary;
  final DateTime generatedAt;
  final int sourceCount;

  const ReviewAiSummaryResult({
    required this.summary,
    required this.generatedAt,
    required this.sourceCount,
  });
}

class _CachedSummary {
  final DateTime createdAt;
  final ReviewAiSummaryResult value;

  const _CachedSummary({
    required this.createdAt,
    required this.value,
  });
}

class ReviewAiSummaryService {
  ReviewAiSummaryService._();
  static final ReviewAiSummaryService instance = ReviewAiSummaryService._();

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const Duration _cacheTtl = Duration(hours: 6);
  static const List<String> _models = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 40),
      headers: const {
        'Content-Type': 'application/json',
      },
    ),
  );

  final Map<String, _CachedSummary> _cache = {};

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  String friendlyError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode ?? 0;
      if (status == 503) {
        return 'AI dang qua tai, thu lai sau it giay.';
      }
      if (status == 429) {
        return 'AI da het quota hoac vuot gioi han goi. Thu lai sau.';
      }
      if (status == 401 || status == 403) {
        return 'API key Gemini khong hop le hoac khong co quyen.';
      }
    }
    return 'Khong the tao tom tat AI luc nay.';
  }

  Future<ReviewAiSummaryResult?> summarizeMovieReviews({
    required String movieId,
    required String movieTitle,
    required List<ReviewSummaryResponse> reviews,
    required double averageRating,
    bool forceRefresh = false,
  }) async {
    if (!isConfigured || reviews.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    if (!forceRefresh) {
      final cached = _cache[movieId];
      if (cached != null && now.difference(cached.createdAt) <= _cacheTtl) {
        return cached.value;
      }
    }

    final prompt = _buildPrompt(
      movieTitle: movieTitle,
      reviews: reviews,
      averageRating: averageRating,
    );

    final summary = await _requestSummaryWithFallback(
      prompt,
      reviews: reviews,
      averageRating: averageRating,
    );
    final result = ReviewAiSummaryResult(
      summary: summary,
      generatedAt: now,
      sourceCount: reviews.length,
    );
    _cache[movieId] = _CachedSummary(createdAt: now, value: result);
    return result;
  }

  Future<String> _requestSummaryWithFallback(
    String prompt, {
    required List<ReviewSummaryResponse> reviews,
    required double averageRating,
  }) async {
    Object? lastError;
    for (final model in _models) {
      try {
        final response = await _postWithRetry(model: model, prompt: prompt);
        final summary = _extractText(
          response.data,
          reviews: reviews,
          averageRating: averageRating,
        );
        if (summary != null && summary.trim().isNotEmpty) {
          return summary.trim();
        }
      } catch (error) {
        lastError = error;
        if (!_canTryNextModel(error)) {
          rethrow;
        }
      }
    }

    if (lastError != null) {
      throw lastError;
    }
    throw Exception('AI summary response is empty');
  }

  Future<Response<dynamic>> _postWithRetry({
    required String model,
    required String prompt,
    int maxAttempts = 3,
  }) async {
    var attempt = 0;
    while (attempt < maxAttempts) {
      attempt++;
      try {
        return await _dio.post(
          '/models/$model:generateContent',
          queryParameters: {'key': _apiKey},
          data: {
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.35,
              'maxOutputTokens': 420,
            },
          },
        );
      } on DioException catch (error) {
        if (!_isTransientError(error) || attempt >= maxAttempts) {
          rethrow;
        }
        await Future.delayed(_backoffFor(error, attempt));
      }
    }
    throw Exception('Retry failed');
  }

  bool _canTryNextModel(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode ?? 0;
      return status == 429 ||
          status == 500 ||
          status == 502 ||
          status == 503 ||
          status == 504 ||
          status == 404;
    }
    return false;
  }

  bool _isTransientError(DioException error) {
    final status = error.response?.statusCode ?? 0;
    return status == 429 ||
        status == 500 ||
        status == 502 ||
        status == 503 ||
        status == 504;
  }

  Duration _backoffFor(DioException error, int attempt) {
    final retry = _readRetryDelay(error);
    if (retry != null) {
      final millis = retry.inMilliseconds;
      if (millis <= 0) {
        return Duration(milliseconds: 600 * attempt);
      }
      if (millis > 8000) {
        return const Duration(seconds: 8);
      }
      return retry;
    }

    if (attempt <= 1) {
      return const Duration(milliseconds: 700);
    }
    if (attempt == 2) {
      return const Duration(milliseconds: 1500);
    }
    return const Duration(milliseconds: 2500);
  }

  Duration? _readRetryDelay(DioException error) {
    final payload = error.response?.data;
    if (payload is! Map<String, dynamic>) {
      return null;
    }
    final err = payload['error'];
    if (err is! Map<String, dynamic>) {
      return null;
    }
    final details = err['details'];
    if (details is! List) {
      return null;
    }

    for (final item in details) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final retryDelay = item['retryDelay'];
      if (retryDelay is! String || retryDelay.isEmpty) {
        continue;
      }
      final raw = retryDelay.trim();
      if (!raw.endsWith('s')) {
        continue;
      }
      final seconds = int.tryParse(raw.substring(0, raw.length - 1));
      if (seconds == null) {
        continue;
      }
      return Duration(seconds: seconds);
    }
    return null;
  }

  String _buildPrompt({
    required String movieTitle,
    required List<ReviewSummaryResponse> reviews,
    required double averageRating,
  }) {
    final snippets = reviews
        .take(20)
        .map((item) {
          final text = _sanitize(item.commentTruncated);
          final safeText = text.isEmpty ? 'Khong co noi dung' : text;
          return '- ${item.rating}/10: $safeText';
        })
        .join('\n');

    return '''
Tom tat review khan gia cho phim "$movieTitle".

Diem trung binh hien tai: ${averageRating.toStringAsFixed(1)}/10
Tong so review mau: ${reviews.length}

Du lieu review:
$snippets

Yeu cau:
- Tra loi bang tieng Viet, khong can markdown.
- Bat buoc co dung 4 dong, moi dong it nhat 10 tu.
- Bat buoc dung dung 4 nhan sau:
Tong quan:
Diem manh:
Can luu y:
De xuat doi tuong:
- Chi dua tren du lieu review ben tren, khong bia.
''';
  }

  String _sanitize(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _extractText(
    dynamic payload, {
    required List<ReviewSummaryResponse> reviews,
    required double averageRating,
  }) {
    if (payload is! Map<String, dynamic>) {
      return null;
    }

    final candidates = payload['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return null;
    }

    final first = candidates.first;
    if (first is! Map<String, dynamic>) {
      return null;
    }

    final content = first['content'];
    if (content is! Map<String, dynamic>) {
      return null;
    }

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) {
      return null;
    }

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is! Map<String, dynamic>) {
        continue;
      }
      final text = part['text'];
      if (text is! String) {
        continue;
      }
      final trimmed = text.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }
      buffer.write(trimmed);
    }
    if (buffer.isEmpty) {
      return null;
    }
    return _normalizeSummary(
      buffer.toString(),
      reviews: reviews,
      averageRating: averageRating,
    );
  }

  String _normalizeSummary(
    String raw, {
    required List<ReviewSummaryResponse> reviews,
    required double? averageRating,
  }) {
    final normalized = raw.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) {
      return _fallbackSummary(reviews, averageRating);
    }

    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final hasAllLabels = lines.any((line) => line.startsWith('Tong quan:')) &&
        lines.any((line) => line.startsWith('Diem manh:')) &&
        lines.any((line) => line.startsWith('Can luu y:')) &&
        lines.any((line) => line.startsWith('De xuat doi tuong:'));

    final seemsTruncated = normalized.length < 75 ||
        normalized.endsWith(':') ||
        normalized.endsWith(',') ||
        normalized.endsWith('rat') ||
        normalized.endsWith('rất');

    if (hasAllLabels && !seemsTruncated) {
      return normalized;
    }

    return _fallbackSummary(reviews, averageRating);
  }

  String _fallbackSummary(
    List<ReviewSummaryResponse> reviews,
    double? averageRating,
  ) {
    if (reviews.isEmpty) {
      return 'Tong quan: Chua co du du lieu review.\n'
          'Diem manh: Chua xac dinh.\n'
          'Can luu y: Chua xac dinh.\n'
          'De xuat doi tuong: Co them review de danh gia ro hon.';
    }

    final high = reviews.where((item) => item.rating >= 8).length;
    final mid = reviews.where((item) => item.rating >= 6 && item.rating < 8).length;
    final low = reviews.where((item) => item.rating < 6).length;

    final avg = averageRating ?? 0;
    final scoreLabel = avg > 0 ? '${avg.toStringAsFixed(1)}/10' : 'chua ro';
    final sentiment = high >= low ? 'tich cuc' : 'trai chieu';

    final topComment = reviews
        .map((item) => _sanitize(item.commentTruncated))
        .firstWhere((text) => text.isNotEmpty, orElse: () => '');

    final shortComment = topComment.length > 90
        ? '${topComment.substring(0, 90)}...'
        : topComment;

    final strengthText = shortComment.isEmpty
        ? 'Khan gia nghiêng ve cam nhan kha on dinh.'
        : 'Khan gia nhac den: "$shortComment".';

    return 'Tong quan: Mau review hien co cho thay xu huong $sentiment, diem trung binh $scoreLabel.\n'
        'Diem manh: $strengthText\n'
        'Can luu y: Ty le review thap diem la $low/${reviews.length}, can xem them nhan xet chi tiet.\n'
        'De xuat doi tuong: Phu hop nguoi muon trai nghiem theo xu huong danh gia hien tai ($high tot, $mid trung lap).';
  }
}
