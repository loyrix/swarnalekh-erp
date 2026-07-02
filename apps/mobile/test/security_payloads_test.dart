import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/security/application/security_payloads.dart';

void main() {
  test('decodes backup JSON payload bytes and counts', () {
    final json = jsonEncode({
      'appName': 'SwarnaLekh',
      'data': {'inventoryItems': []},
    });

    final payload = decodeBackupPayload({
      'fileName': 'swarnalekh-backup-2026-06-10.json',
      'mimeType': 'application/json',
      'base64': base64Encode(utf8.encode(json)),
      'counts': {'customers': 2, 'inventoryItems': 3},
    });

    expect(payload.fileName, 'swarnalekh-backup-2026-06-10.json');
    expect(payload.mimeType, 'application/json');
    expect(payload.text, json);
    expect(payload.counts, {'customers': 2, 'inventoryItems': 3});
  });

  test('rejects invalid backup payloads', () {
    expect(() => decodeBackupPayload({}), throwsFormatException);
    expect(
      () => decodeBackupPayload({'fileName': 'backup.json'}),
      throwsFormatException,
    );
  });
}
