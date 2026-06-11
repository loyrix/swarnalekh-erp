import 'dart:convert';
import 'dart:typed_data';

class MortgageReceiptPdfPayload {
  final String fileName;
  final Uint8List bytes;

  const MortgageReceiptPdfPayload({
    required this.fileName,
    required this.bytes,
  });
}

MortgageReceiptPdfPayload decodeMortgageReceiptPdfPayload(
  Map<String, dynamic> payload, {
  required String fallbackFileName,
}) {
  final fileName = payload['fileName']?.toString().trim();
  final base64 = payload['base64']?.toString().trim() ?? '';
  if (base64.isEmpty) {
    throw const FormatException('Mortgage receipt PDF payload is empty');
  }

  return MortgageReceiptPdfPayload(
    fileName: fileName == null || fileName.isEmpty
        ? fallbackFileName
        : fileName,
    bytes: Uint8List.fromList(base64Decode(base64)),
  );
}

String verificationImageDataUri({
  required List<int> bytes,
  required String mimeType,
}) {
  if (bytes.isEmpty) {
    throw const FormatException('Customer Verification image is empty');
  }
  if (!mimeType.startsWith('image/')) {
    throw const FormatException(
      'Customer Verification file must be an image MIME type',
    );
  }

  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}

bool isVerificationDataImage(String value) {
  return value.startsWith('data:image/') && value.contains(';base64,');
}
