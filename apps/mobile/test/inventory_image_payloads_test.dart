import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/inventory/application/inventory_image_payloads.dart';

void main() {
  test('builds and decodes inventory image data URIs', () {
    final dataUri = inventoryImageDataUri(
      bytes: [1, 2, 3, 4],
      mimeType: 'image/jpeg',
    );

    expect(dataUri, startsWith('data:image/jpeg;base64,'));
    expect(isInventoryDataImage(dataUri), isTrue);
    expect(decodeInventoryDataImage(dataUri), [1, 2, 3, 4]);
  });

  test('reads first inventory image from photo list', () {
    expect(
      firstInventoryImage([' https://example.com/ring.jpg ']),
      'https://example.com/ring.jpg',
    );
    expect(firstInventoryImage([]), isNull);
    expect(firstInventoryImage(null), isNull);
  });

  test('rejects invalid inventory image payloads', () {
    expect(
      () => inventoryImageDataUri(bytes: [], mimeType: 'image/jpeg'),
      throwsFormatException,
    );
    expect(
      () => inventoryImageDataUri(bytes: [1], mimeType: 'text/plain'),
      throwsFormatException,
    );
    expect(
      () => decodeInventoryDataImage('https://example.com/a.jpg'),
      throwsFormatException,
    );
  });
}
