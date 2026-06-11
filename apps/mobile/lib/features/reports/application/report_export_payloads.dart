import 'dart:convert';
import 'dart:typed_data';

class ReportPdfPayload {
  final String fileName;
  final Uint8List bytes;

  const ReportPdfPayload({required this.fileName, required this.bytes});
}

ReportPdfPayload decodeReportPdfPayload(
  Map<String, dynamic> payload, {
  required String fallbackFileName,
}) {
  final fileName = payload['fileName']?.toString().trim();
  final base64 = payload['base64']?.toString().trim() ?? '';
  if (base64.isEmpty) {
    throw const FormatException('Report PDF payload is empty');
  }

  return ReportPdfPayload(
    fileName: fileName == null || fileName.isEmpty
        ? fallbackFileName
        : fileName,
    bytes: Uint8List.fromList(base64Decode(base64)),
  );
}
