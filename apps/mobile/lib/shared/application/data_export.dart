import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:printing/printing.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

/// A decoded export file (CSV) from `GET /export/:type`.
class ExportFile {
  const ExportFile({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}

ExportFile decodeExportFile(
  Map<String, dynamic> payload, {
  required String fallbackFileName,
}) {
  final fileName = payload['fileName']?.toString().trim();
  final base64Data = payload['base64']?.toString().trim() ?? '';
  if (base64Data.isEmpty) {
    throw const FormatException('Export payload is empty');
  }
  return ExportFile(
    fileName: fileName == null || fileName.isEmpty
        ? fallbackFileName
        : fileName,
    bytes: Uint8List.fromList(base64Decode(base64Data)),
  );
}

/// Fetches a CSV export from the API and opens the share sheet so the owner can
/// save/send it. Shows a success/failure toast. Admin-only on the server.
Future<void> exportAndShareCsv(
  BuildContext context,
  String type, {
  Map<String, dynamic>? query,
}) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    final response = await ApiClient().dio.get<Map<String, dynamic>>(
      '/export/$type',
      queryParameters: query,
    );
    final file = decodeExportFile(
      response.data ?? const {},
      fallbackFileName: '$type.csv',
    );
    await Printing.sharePdf(bytes: file.bytes, filename: file.fileName);
    if (context.mounted) {
      AppToast.success(context, l10n.exportReady(file.fileName));
    }
  } catch (_) {
    if (context.mounted) AppToast.error(context, l10n.exportFailed);
  }
}
