import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/shared/application/data_export.dart';

void main() {
  group('decodeExportFile', () {
    test('decodes the base64 CSV payload and keeps the file name', () {
      const csv = 'Name,City\r\nAsha,Pune';
      final file = decodeExportFile({
        'fileName': 'customers-2026-06-10.csv',
        'mimeType': 'text/csv',
        'base64': base64Encode(utf8.encode(csv)),
      }, fallbackFileName: 'customers.csv');

      expect(file.fileName, 'customers-2026-06-10.csv');
      expect(utf8.decode(file.bytes), csv);
    });

    test('falls back to the default file name when missing', () {
      final file = decodeExportFile({
        'base64': base64Encode(utf8.encode('A,B')),
      }, fallbackFileName: 'invoices.csv');
      expect(file.fileName, 'invoices.csv');
    });

    test('rejects an empty payload', () {
      expect(
        () => decodeExportFile({}, fallbackFileName: 'x.csv'),
        throwsFormatException,
      );
    });
  });
}
