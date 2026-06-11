import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/reports/application/report_export_payloads.dart';

void main() {
  test('decodes report PDF payload bytes and file name', () {
    final payload = decodeReportPdfPayload({
      'fileName': 'current-stock-2026-06-10.pdf',
      'base64': base64Encode([0x25, 0x50, 0x44, 0x46]),
    }, fallbackFileName: 'report.pdf');

    expect(payload.fileName, 'current-stock-2026-06-10.pdf');
    expect(payload.bytes, [0x25, 0x50, 0x44, 0x46]);
  });

  test('uses fallback file name when report payload omits one', () {
    final payload = decodeReportPdfPayload({
      'base64': base64Encode([1, 2, 3]),
    }, fallbackFileName: 'fallback-report.pdf');

    expect(payload.fileName, 'fallback-report.pdf');
    expect(payload.bytes, [1, 2, 3]);
  });

  test('rejects invalid report PDF payloads', () {
    expect(
      () => decodeReportPdfPayload({}, fallbackFileName: 'report.pdf'),
      throwsFormatException,
    );
  });
}
