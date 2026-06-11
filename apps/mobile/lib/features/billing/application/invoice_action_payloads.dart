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
  final base64 = payload['base64']?.toString().trim() ?? '';
  if (base64.isEmpty) {
    throw const FormatException('Invoice PDF payload is empty');
  }

  return InvoicePdfPayload(
    fileName: fileName == null || fileName.isEmpty
        ? fallbackFileName
        : fileName,
    bytes: Uint8List.fromList(base64Decode(base64)),
  );
}

Uri invoiceWhatsAppUri(Map<String, dynamic> payload) {
  final value = payload['whatsappUrl']?.toString().trim() ?? '';
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw const FormatException('Invalid WhatsApp invoice URL');
  }
  return uri;
}
