import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:swarnbook/shared/application/data_image.dart';

void main() {
  group('imageDataUri', () {
    test('builds and decodes a base64 image data URI', () {
      final uri = imageDataUri(bytes: [1, 2, 3], mimeType: 'image/jpeg');

      expect(uri, 'data:image/jpeg;base64,AQID');
      expect(isDataImage(uri), isTrue);
      expect(decodeDataImage(uri), [1, 2, 3]);
    });

    test('rejects empty or non-image input', () {
      expect(
        () => imageDataUri(bytes: const [], mimeType: 'image/jpeg'),
        throwsFormatException,
      );
      expect(
        () => imageDataUri(bytes: const [1], mimeType: 'application/pdf'),
        throwsFormatException,
      );
      expect(
        () => decodeDataImage('https://example.test/logo.png'),
        throwsFormatException,
      );
    });

    test('normalizes decodable images to JPEG data URIs', () {
      final pngBytes = image.encodePng(image.Image(width: 1, height: 1));

      final uri = jpegImageDataUri(bytes: pngBytes);
      final decoded = decodeDataImage(uri);

      expect(uri, startsWith('data:image/jpeg;base64,'));
      expect(decoded.take(2), [0xff, 0xd8]);
    });
  });

  group('mimeTypeForImageName', () {
    test('uses common image extensions', () {
      expect(mimeTypeForImageName('logo.png'), 'image/png');
      expect(mimeTypeForImageName('logo.webp'), 'image/webp');
      expect(mimeTypeForImageName('logo.jpg'), 'image/jpeg');
      expect(mimeTypeForImageName('logo.jpeg'), 'image/jpeg');
      expect(mimeTypeForImageName('logo'), 'image/jpeg');
    });
  });
}
