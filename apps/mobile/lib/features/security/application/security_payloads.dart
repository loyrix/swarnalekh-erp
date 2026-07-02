import 'dart:convert';
import 'dart:typed_data';

class BackupPayload {
  final String fileName;
  final String mimeType;
  final Uint8List bytes;
  final Map<String, int> counts;

  const BackupPayload({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
    required this.counts,
  });

  String get text => utf8.decode(bytes);
}

BackupPayload decodeBackupPayload(Map<String, dynamic> payload) {
  final fileName = payload['fileName']?.toString().trim();
  final mimeType = payload['mimeType']?.toString().trim();
  final base64 = payload['base64']?.toString().trim() ?? '';

  if (fileName == null || fileName.isEmpty) {
    throw const FormatException('Backup file name is missing');
  }
  if (base64.isEmpty) {
    throw const FormatException('Backup payload is empty');
  }

  return BackupPayload(
    fileName: fileName,
    mimeType: mimeType == null || mimeType.isEmpty
        ? 'application/json'
        : mimeType,
    bytes: Uint8List.fromList(base64Decode(base64)),
    counts: _parseCounts(payload['counts']),
  );
}

Map<String, int> _parseCounts(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, count) {
    final parsedCount = count is num ? count.toInt() : int.tryParse('$count');
    return MapEntry(key.toString(), parsedCount ?? 0);
  });
}
