import 'dart:convert';
import 'dart:typed_data';

class InvoicePdfPayload {
  final String fileName;
  final Uint8List bytes;

  const InvoicePdfPayload({required this.fileName, required this.bytes});
}

InvoicePdfPayload decodeInvoicePdfPayload(
  Map<String, dynamic> payload, {
  required String fallbackFileName,
}) {
  final fileName = payload['fileName']?.toString().trim();
  final mimeType = payload['mimeType']?.toString().trim();
  final base64 = payload['base64']?.toString().trim() ?? '';
  if (base64.isEmpty) {
    throw const FormatException('Invoice PDF payload is empty');
  }
  if (mimeType != null &&
      mimeType.isNotEmpty &&
      mimeType != 'application/pdf') {
    throw const FormatException('Invoice payload is not a PDF');
  }

  final bytes = Uint8List.fromList(base64Decode(base64));
  if (bytes.length < 4 ||
      bytes[0] != 0x25 ||
      bytes[1] != 0x50 ||
      bytes[2] != 0x44 ||
      bytes[3] != 0x46) {
    throw const FormatException('Invoice payload is not a valid PDF');
  }

  return InvoicePdfPayload(
    fileName: fileName == null || fileName.isEmpty
        ? fallbackFileName
        : fileName,
    bytes: bytes,
  );
}

Uri invoiceWhatsAppUri(Map<String, dynamic> payload) {
  final value = payload['whatsappUrl']?.toString().trim() ?? '';
  final uri = Uri.tryParse(value);
  final allowedHosts = {'wa.me', 'api.whatsapp.com', 'web.whatsapp.com'};
  if (uri == null ||
      uri.scheme != 'https' ||
      !allowedHosts.contains(uri.host.toLowerCase())) {
    throw const FormatException('Invalid WhatsApp invoice URL');
  }
  return uri;
}
