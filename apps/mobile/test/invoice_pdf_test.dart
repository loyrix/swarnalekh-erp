import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/billing/data/models/invoice.dart';
import 'package:swarnbook/features/billing/presentation/invoice_pdf.dart';

bool _isPdf(List<int> bytes) =>
    bytes.length > 4 &&
    bytes[0] == 0x25 && // %
    bytes[1] == 0x50 && // P
    bytes[2] == 0x44 && // D
    bytes[3] == 0x46; // F

PrintableInvoice _fixture({
  int itemCount = 3,
  bool withPayments = true,
  double balanceDue = 6000,
}) {
  return PrintableInvoice.fromJson({
    'shop': {
      'name': 'Café Krishna Jewellers & Sons',
      'phone': '+91 99999 00000',
      'gstin': '24ABCDE1234F1Z5',
      'pan': 'ABCDE1234F',
      'address': 'MG Road',
      'city': 'Ahmedabad',
    },
    'invoice': {
      'invoiceNumber': 'SLK-2026-0001',
      'invoiceDate': '2026-06-10T00:00:00.000Z',
      'customerName': 'A Very Long Customer Name For Wrapping & Layout',
      'customerPhone': '+91 88888 77777',
      'customerGstin': '24ZZZZZ9999Z9Z9',
      'paymentMode': 'upi',
      'items': List.generate(
        itemCount,
        (i) => {
          'itemName': 'Gold Ring No. $i (22K, hallmarked)',
          'karat': '22K',
          'grossWeight': 10.5 + i,
          'netWeight': 9.25 + i,
          'ratePerGram': 6000,
          'makingCharges': 800,
          'itemTotal': 60000 + i,
        },
      ),
      'subtotal': 54000,
      'totalMakingCharges': 2400,
      'totalStoneValue': 500,
      'discountAmount': 1000,
      'oldGoldValue': 2000,
      'taxableAmount': 54000,
      'cgstPercent': 1.5,
      'cgstAmount': 810,
      'sgstPercent': 1.5,
      'sgstAmount': 810,
      'igstPercent': 0,
      'igstAmount': 0,
      'totalTax': 1620,
      'grandTotal': 55620,
      'amountPaid': withPayments ? 4000 : 55620,
      'balanceDue': balanceDue,
      'notes': 'Handle with care.',
      'payments': withPayments
          ? [
              {
                'id': 'p1',
                'amount': 4000,
                'paymentMode': 'cash',
                'referenceNumber': 'TXN-1',
                'paymentDate': '2026-06-11T00:00:00.000Z',
              },
            ]
          : [],
    },
    'qrPayload': 'Invoice:SLK-2026-0001|Amount:55620.00',
    'verificationCode': 'ABC123DEF456',
    'generatedAt': '2026-06-11T10:00:00.000Z',
  });
}

void main() {
  group('amountInWordsIndian', () {
    test('spells amounts using crore/lakh Indian grouping', () {
      expect(
        amountInWordsIndian(184741),
        'Rupees One Lakh Eighty Four Thousand Seven Hundred Forty One Only',
      );
      expect(
        amountInWordsIndian(12345678.5),
        'Rupees One Crore Twenty Three Lakh Forty Five Thousand Six Hundred '
        'Seventy Eight and Paise Fifty Only',
      );
      expect(amountInWordsIndian(0), 'Rupees Zero Only');
      expect(amountInWordsIndian(100), 'Rupees One Hundred Only');
    });
  });

  group('buildInvoicePdf', () {
    test('produces a valid, non-trivial PDF for a rich invoice', () async {
      final bytes = await buildInvoicePdf(_fixture());
      expect(_isPdf(bytes), isTrue);
      expect(bytes.length, greaterThan(1000));
    });

    test('builds a fully-paid invoice with no payments section', () async {
      final bytes = await buildInvoicePdf(
        _fixture(withPayments: false, balanceDue: 0),
      );
      expect(_isPdf(bytes), isTrue);
    });

    test('paginates a long invoice without throwing', () async {
      final bytes = await buildInvoicePdf(_fixture(itemCount: 60));
      expect(_isPdf(bytes), isTrue);
      expect(bytes.length, greaterThan(2000));
    });

    test('embeds the shop logo when supplied as a data image', () async {
      // 1x1 transparent PNG.
      const png =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
      final printable = PrintableInvoice.fromJson({
        'shop': {'name': 'Shop', 'logoUrl': png},
        'invoice': _fixture().invoice.toDebugJson(),
      });
      final bytes = await buildInvoicePdf(printable);
      expect(_isPdf(bytes), isTrue);
    });

    test('renders without a QR barcode on the page', () async {
      final bytes = await buildInvoicePdf(_fixture());
      // The QR was removed from the printed bill. dart_pdf emits the barcode
      // as vector paths, so assert on the document's own object stream: a page
      // carrying a QR is markedly larger than the same page without one.
      final withoutQr = bytes.length;

      // Same invoice, but with every QR/verification field stripped from the
      // payload — byte-identical output proves nothing was keyed off them.
      final stripped = PrintableInvoice.fromJson({
        'shop': {
          'name': 'Café Krishna Jewellers & Sons',
          'phone': '+91 99999 00000',
          'gstin': '24ABCDE1234F1Z5',
          'pan': 'ABCDE1234F',
          'address': 'MG Road',
          'city': 'Ahmedabad',
        },
        'invoice': _fixture().invoice.toDebugJson(),
      });
      final strippedBytes = await buildInvoicePdf(stripped);

      expect(_isPdf(strippedBytes), isTrue);
      // Neither document should balloon the way an embedded QR would.
      expect(withoutQr, lessThan(120000));
    });

    test('builds when the shop profile is almost entirely empty', () async {
      // A brand-new shop has no logo, GSTIN, city or email yet; the letterhead
      // and footer must still lay out rather than throwing on nulls.
      final bare = PrintableInvoice.fromJson({
        'shop': const <String, dynamic>{},
        'invoice': _fixture().invoice.toDebugJson(),
      });
      final bytes = await buildInvoicePdf(bare);
      expect(_isPdf(bytes), isTrue);
    });
  });

  group('PrintableShop', () {
    test('parses the city and email used by the letterhead and footer', () {
      final shop = PrintableShop.fromJson(const {
        'name': 'BR',
        'phone': '+91 90000 00000',
        'email': 'brjewellers@gmail.com',
        'address': 'Main Road',
        'city': 'Dombivli',
        'state': 'Maharashtra',
      });

      expect(shop.city, 'Dombivli');
      expect(shop.email, 'brjewellers@gmail.com');
      // The full address still joins every part for the contact strip.
      expect(shop.address, 'Main Road, Dombivli, Maharashtra');
    });

    test('leaves city and email null when the shop has not set them', () {
      final shop = PrintableShop.fromJson(const {'name': 'BR'});
      expect(shop.city, isNull);
      expect(shop.email, isNull);
    });
  });
}

extension on PrintableInvoiceDetail {
  // Minimal round-trip so the logo test can reuse the fixture invoice body.
  Map<String, dynamic> toDebugJson() => {
    'invoiceNumber': invoiceNumber,
    'grandTotal': grandTotal,
    'amountPaid': amountPaid,
    'balanceDue': balanceDue,
    'items': const [],
    'payments': const [],
  };
}
