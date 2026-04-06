import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_system_app/core/utils/image_url_resolver.dart';
import 'package:cinema_booking_system_app/core/network/parsers/api_payload_parser.dart';

void main() {
  group('ApiPayloadParser', () {
    test('unwrap returns nested data payload', () {
      final payload = {
        'success': true,
        'data': {'id': 'movie-1', 'title': 'Interstellar'},
      };

      final result = ApiPayloadParser.unwrap(payload);

      expect(result, isA<Map<String, dynamic>>());
      expect(result['id'], 'movie-1');
      expect(result['title'], 'Interstellar');
    });

    test('extractMessage prefers nested message', () {
      final payload = {
        'success': false,
        'data': {'message': 'Room already scheduled'},
      };

      expect(
        ApiPayloadParser.extractMessage(payload),
        'Room already scheduled',
      );
    });

    test('page parses backend pagination shape', () {
      final payload = {
        'success': true,
        'data': {
          'items': [
            {'id': '1', 'name': 'Cinema A'},
            {'id': '2', 'name': 'Cinema B'},
          ],
          'page': 1,
          'size': 10,
          'totalPages': 5,
          'totalElements': 42,
          'first': false,
          'last': false,
        },
      };

      final page = ApiPayloadParser.page<Map<String, dynamic>>(
        payload,
        (json) => json,
      );

      expect(page.content.length, 2);
      expect(page.content.first['name'], 'Cinema A');
      expect(page.number, 1);
      expect(page.currentPage, 2);
      expect(page.totalPages, 5);
      expect(page.totalElements, 42);
      expect(page.first, isFalse);
      expect(page.last, isFalse);
    });
  });

  group('ImageUrlResolver', () {
    test('extracts url from stringified upload object', () {
      const raw =
          '{url: https://res.cloudinary.com/demo/image/upload/v1/sample.jpg, publicId: images/sample, format: jpg, resourceType: image}';

      final resolved = ImageUrlResolver.normalize(raw);

      expect(
        resolved,
        'https://res.cloudinary.com/demo/image/upload/v1/sample.jpg',
      );
    });
  });
}
