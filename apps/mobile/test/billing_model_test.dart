import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/billing/data/invoice_repository.dart';
import 'package:swarnbook/features/billing/data/models/invoice.dart';

void main() {
  group('Invoice.fromJson', () {
    test('parses money, item count and paid status', () {
      final inv = Invoice.fromJson({
        'id': 'i1',
        'invoiceNumber': 'SLK-2026-0001',
        'customerName': 'Asha',
        'grandTotal': '15000',
        'amountPaid': 15000,
        'balanceDue': '0',
        'items': [
          {'id': 'a'},
          {'id': 'b'},
        ],
      });
      expect(inv.id, 'i1');
      expect(inv.invoiceNumber, 'SLK-2026-0001');
      expect(inv.grandTotal, 15000);
      expect(inv.itemCount, 2);
      expect(inv.isPaid, isTrue);
    });

    test('pending when balance remains and safe defaults', () {
      final inv = Invoice.fromJson({'id': 'x', 'balanceDue': 500});
      expect(inv.isPaid, isFalse);
      expect(inv.grandTotal, 0);
      expect(inv.itemCount, 0);
      expect(inv.customerName, isNull);
    });
  });

  group('BillingDashboard.fromJson', () {
    test('parses revenue, counts and top selling products', () {
      final d = BillingDashboard.fromJson({
        'todaysRevenue': '1200',
        'monthlyRevenue': 45000,
        'totalBills': '12',
        'averageBillValue': 3750,
        'topSellingProducts': [
          {'itemName': 'Ring', 'quantity': 5},
          {'itemName': 'Chain', 'quantity': '3'},
        ],
      });
      expect(d.todaysRevenue, 1200);
      expect(d.totalBills, 12);
      expect(d.topSellingProducts, hasLength(2));
      expect(d.topSellingProducts.first.itemName, 'Ring');
      expect(d.topSellingProducts[1].quantity, 3);
    });
  });

  group('InvoicePreview.fromJson', () {
    test('computes product value and total units from lines', () {
      final p = InvoicePreview.fromJson({
        'items': [
          {
            'inventoryItemId': 'a',
            'itemName': 'Ring x2',
            'quantity': 2,
            'netWeight': 4,
            'metalValue': 8000,
            'makingCharges': 1000,
            'itemTotal': 9000,
          },
          {
            'inventoryItemId': 'b',
            'quantity': 1,
            'metalValue': '2000',
            'itemTotal': 2500,
          },
        ],
        'subtotal': 11500,
        'totalMakingCharges': 1000,
        'totalTax': 345,
        'grandTotal': 11845,
      });
      expect(p.items, hasLength(2));
      expect(p.productValue, 10000);
      expect(p.totalUnits, 3);
      expect(p.grandTotal, 11845);
      expect(p.totalTax, 345);
    });
  });

  group('BillingInventoryItem.fromJson', () {
    test('defaults unique stock to a single available piece', () {
      final item = BillingInventoryItem.fromJson({
        'id': 'u1',
        'itemName': 'Bangle',
        'stockType': 'unique',
        'tagNumber': 'TAG-9',
      });
      expect(item.isBulk, isFalse);
      expect(item.availableQuantity, 1);
      expect(item.matches('bangle'), isTrue);
      expect(item.matches('tag-9'), isTrue);
      expect(item.matches('nope'), isFalse);
    });

    test('bulk item keeps its available quantity', () {
      final item = BillingInventoryItem.fromJson({
        'id': 'b1',
        'stockType': 'bulk',
        'quantity': 7,
      });
      expect(item.isBulk, isTrue);
      expect(item.availableQuantity, 7);
    });
  });

  group('InvoiceQuery', () {
    test('omits empty search/date params', () {
      const q = InvoiceQuery();
      expect(q.toQueryParameters(), isNull);
    });

    test('includes trimmed search and dates', () {
      const q = InvoiceQuery(
        search: '  asha ',
        dateFrom: '2026-06-01',
        dateTo: '2026-06-30',
      );
      final params = q.toQueryParameters()!;
      expect(params['search'], 'asha');
      expect(params['dateFrom'], '2026-06-01');
      expect(params['dateTo'], '2026-06-30');
    });

    test('value equality keys the provider family', () {
      const a = InvoiceQuery(search: 'x', dateFrom: '2026-01-01');
      final b = const InvoiceQuery().copyWith(
        search: 'x',
        dateFrom: '2026-01-01',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('InvoiceDraft.toJson', () {
    test('sends saved customer id and omits typed name', () {
      final draft = InvoiceDraft(
        customerId: 'c1',
        customerName: 'ignored',
        items: const [InvoiceDraftItem(inventoryItemId: 'a', quantity: 1)],
        discountAmount: 100,
        amountPaid: 500,
        paymentMode: 'upi',
      );
      final json = draft.toJson(idempotencyKey: 'key-1');
      expect(json['customerId'], 'c1');
      expect(json.containsKey('customerName'), isFalse);
      expect(json['idempotencyKey'], 'key-1');
      expect((json['items'] as List).first['quantity'], 1);
      expect(json['discountAmount'], 100);
      expect(json['paymentMode'], 'upi');
    });

    test('walk-in sends typed name/phone and omits key when absent', () {
      final draft = InvoiceDraft(
        customerName: 'Walk In',
        customerPhone: '99999',
        items: const [InvoiceDraftItem(inventoryItemId: 'a', quantity: 2)],
      );
      final json = draft.toJson();
      expect(json['customerName'], 'Walk In');
      expect(json['customerPhone'], '99999');
      expect(json.containsKey('customerId'), isFalse);
      expect(json.containsKey('idempotencyKey'), isFalse);
    });
  });

  group('PrintableInvoice.fromJson', () {
    test('parses shop, invoice items and protection fields', () {
      final printable = PrintableInvoice.fromJson({
        'shop': {
          'name': 'SwarnaLekh',
          'phone': '111',
          'gstin': 'GST1',
          'address': 'Main Rd',
          'city': 'Pune',
        },
        'invoice': {
          'invoiceNumber': 'SLK-2026-0001',
          'invoiceDate': '2026-06-10T00:00:00.000Z',
          'customerName': 'Asha',
          'grandTotal': 15000,
          'amountPaid': 10000,
          'balanceDue': 5000,
          'items': [
            {
              'itemName': 'Ring',
              'karat': '22K',
              'grossWeight': 5,
              'netWeight': 4.5,
              'ratePerGram': 6000,
              'makingCharges': 800,
              'itemTotal': 9000,
            },
          ],
        },
        'qrPayload': 'Invoice:SLK-2026-0001',
        'verificationCode': 'ABC123',
        'generatedAt': '2026-06-10T10:00:00.000Z',
      });
      expect(printable.shop.name, 'SwarnaLekh');
      expect(printable.shop.address, 'Main Rd, Pune');
      expect(printable.invoice.items, hasLength(1));
      expect(printable.invoice.items.first.netWeight, 4.5);
      expect(printable.invoice.grandTotal, 15000);
      expect(printable.verificationCode, 'ABC123');
      expect(printable.invoice.invoiceDate?.year, 2026);
    });
  });
}
