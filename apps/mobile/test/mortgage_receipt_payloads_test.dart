import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/mortgage/application/mortgage_receipt_payloads.dart';

void main() {
  test('decodes mortgage receipt PDF payload bytes and file name', () {
    final payload = decodeMortgageReceiptPdfPayload({
      'fileName': 'MR-2026-0001.pdf',
      'base64': base64Encode([0x25, 0x50, 0x44, 0x46]),
    }, fallbackFileName: 'receipt.pdf');

    expect(payload.fileName, 'MR-2026-0001.pdf');
    expect(payload.bytes, [0x25, 0x50, 0x44, 0x46]);
  });

  test('uses fallback file name when receipt payload omits one', () {
    final payload = decodeMortgageReceiptPdfPayload({
      'base64': base64Encode([1, 2, 3]),
    }, fallbackFileName: 'mortgage-receipt.pdf');

    expect(payload.fileName, 'mortgage-receipt.pdf');
    expect(payload.bytes, [1, 2, 3]);
  });

  test('builds Customer Verification image data URI', () {
    final uri = verificationImageDataUri(
      bytes: [1, 2, 3],
      mimeType: 'image/jpeg',
    );

    expect(uri, 'data:image/jpeg;base64,AQID');
    expect(isVerificationDataImage(uri), isTrue);
  });

  test('rejects invalid mortgage receipt and image payloads', () {
    expect(
      () => decodeMortgageReceiptPdfPayload(
        {},
        fallbackFileName: 'mortgage-receipt.pdf',
      ),
      throwsFormatException,
    );
    expect(
      () => verificationImageDataUri(bytes: [], mimeType: 'image/jpeg'),
      throwsFormatException,
    );
    expect(
      () => verificationImageDataUri(bytes: [1], mimeType: 'text/plain'),
      throwsFormatException,
    );
  });
}
