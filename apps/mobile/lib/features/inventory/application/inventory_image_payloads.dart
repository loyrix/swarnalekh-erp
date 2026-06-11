import 'dart:convert';
import 'dart:typed_data';

String inventoryImageDataUri({
  required List<int> bytes,
  required String mimeType,
}) {
  if (bytes.isEmpty) {
    throw const FormatException('Inventory image is empty');
  }
  if (!mimeType.startsWith('image/')) {
    throw const FormatException('Inventory image must be an image MIME type');
  }

  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}

String? firstInventoryImage(dynamic photos) {
  if (photos is! List || photos.isEmpty) return null;
  final value = photos.first?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

bool isInventoryDataImage(String value) {
  return value.startsWith('data:image/') && value.contains(';base64,');
}

Uint8List decodeInventoryDataImage(String value) {
  if (!isInventoryDataImage(value)) {
    throw const FormatException('Invalid inventory data image');
  }

  final parts = value.split(';base64,');
  if (parts.length != 2 || parts[1].isEmpty) {
    throw const FormatException('Invalid inventory data image');
  }

  return Uint8List.fromList(base64Decode(parts[1]));
}
