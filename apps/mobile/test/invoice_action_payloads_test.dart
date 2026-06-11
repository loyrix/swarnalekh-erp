import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/billing/application/invoice_action_payloads.dart';

void main() {
  test('decodes invoice PDF payload bytes and file name', () {
    final payload = decodeInvoicePdfPayload({
      'fileName': 'SLK-2026-0001.pdf',
      'base64': base64Encode([0x25, 0x50, 0x44, 0x46]),
    }, fallbackFileName: 'invoice.pdf');

    expect(payload.fileName, 'SLK-2026-0001.pdf');
    expect(payload.bytes, [0x25, 0x50, 0x44, 0x46]);
  });

  test('uses fallback file name when PDF payload omits one', () {
    final payload = decodeInvoicePdfPayload({
      'base64': base64Encode([1, 2, 3]),
    }, fallbackFileName: 'invoice-fallback.pdf');

    expect(payload.fileName, 'invoice-fallback.pdf');
    expect(payload.bytes, [1, 2, 3]);
  });

  test('parses WhatsApp invoice URL', () {
    final uri = invoiceWhatsAppUri({
      'whatsappUrl': 'https://wa.me/?text=Invoice%20SLK-2026-0001',
    });

    expect(uri.scheme, 'https');
    expect(uri.host, 'wa.me');
    expect(uri.queryParameters['text'], 'Invoice SLK-2026-0001');
  });

  test('rejects invalid invoice action payloads', () {
    expect(
      () => decodeInvoicePdfPayload({}, fallbackFileName: 'invoice.pdf'),
      throwsFormatException,
    );
    expect(
      () => invoiceWhatsAppUri({'whatsappUrl': 'not a url'}),
      throwsFormatException,
    );
  });
}
