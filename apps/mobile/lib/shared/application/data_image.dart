import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as image;

String imageDataUri({required List<int> bytes, required String mimeType}) {
  if (bytes.isEmpty) {
    throw const FormatException('Image is empty');
  }
  if (!mimeType.startsWith('image/')) {
    throw const FormatException('File must be an image MIME type');
  }

  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}

String jpegImageDataUri({required List<int> bytes, int quality = 82}) {
  if (bytes.isEmpty) {
    throw const FormatException('Image is empty');
  }

  final decoded = image.decodeImage(Uint8List.fromList(bytes));
  if (decoded == null) {
    throw const FormatException('Invalid image');
  }

  final normalizedQuality = quality.clamp(1, 100).toInt();
  final encoded = image.encodeJpg(decoded, quality: normalizedQuality);
  return imageDataUri(bytes: encoded, mimeType: 'image/jpeg');
}

bool isDataImage(String value) {
  return value.startsWith('data:image/') && value.contains(';base64,');
}

Uint8List decodeDataImage(String value) {
  if (!isDataImage(value)) {
    throw const FormatException('Invalid data image');
  }

  final parts = value.split(';base64,');
  if (parts.length != 2 || parts[1].isEmpty) {
    throw const FormatException('Invalid data image');
  }

  return Uint8List.fromList(base64Decode(parts[1]));
}

String mimeTypeForImageName(String name) {
  final lowerName = name.toLowerCase();
  if (lowerName.endsWith('.png')) return 'image/png';
  if (lowerName.endsWith('.webp')) return 'image/webp';
  if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  return 'image/jpeg';
}
