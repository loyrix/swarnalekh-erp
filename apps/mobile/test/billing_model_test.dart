import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/billing/data/invoice_repository.dart';
import 'package:swarnbook/features/billing/data/models/invoice.dart';
import 'package:swarnbook/features/billing/presentation/billing_format.dart';

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

    test('parses karat and rate per gram on each line', () {
      final line = InvoicePreviewLine.fromJson({
        'inventoryItemId': 'a',
        'itemName': 'Gold Chain',
        'karat': '22K',
        'quantity': 1,
        'netWeight': 10,
        'ratePerGram': 7320,
        'metalValue': 73200,
        'makingCharges': 500,
        'itemTotal': 73700,
      });
      expect(line.karat, '22K');
      expect(line.ratePerGram, 7320);
      // Absent rate (explicit selling price) parses as 0.
      expect(
        InvoicePreviewLine.fromJson({
          'inventoryItemId': 'b',
          'quantity': 1,
        }).ratePerGram,
        0,
      );
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
        items: const [
          InvoiceDraftItem.inventory(inventoryItemId: 'a', quantity: 1),
        ],
        amountPaid: 500,
        paymentMode: 'upi',
      );
      final json = draft.toJson(idempotencyKey: 'key-1');
      expect(json['customerId'], 'c1');
      expect(json.containsKey('customerName'), isFalse);
      expect(json['idempotencyKey'], 'key-1');
      expect((json['items'] as List).first['quantity'], 1);
      expect(json['paymentMode'], 'upi');
    });

    test('walk-in sends typed name/phone and omits key when absent', () {
      final draft = InvoiceDraft(
        customerName: 'Walk In',
        customerPhone: '99999',
        items: const [
          InvoiceDraftItem.inventory(inventoryItemId: 'a', quantity: 2),
        ],
      );
      final json = draft.toJson();
      expect(json['customerName'], 'Walk In');
      expect(json['customerPhone'], '99999');
      expect(json.containsKey('customerId'), isFalse);
      expect(json.containsKey('idempotencyKey'), isFalse);
    });

    test('never sends a discount — the field is gone from the bill', () {
      final draft = InvoiceDraft(
        customerName: 'Walk In',
        items: const [
          InvoiceDraftItem.inventory(inventoryItemId: 'a', quantity: 1),
        ],
      );
      expect(draft.toJson().containsKey('discountAmount'), isFalse);
    });

    test('sends the old gold amount only when it is greater than zero', () {
      const items = [
        InvoiceDraftItem.inventory(inventoryItemId: 'a', quantity: 1),
      ];
      expect(
        InvoiceDraft(
          customerName: 'Walk In',
          items: items,
          oldGoldValue: 12000,
        ).toJson()['oldGoldValue'],
        12000,
      );
      // Switched off, or typed as zero, sends nothing at all.
      expect(
        InvoiceDraft(
          customerName: 'Walk In',
          items: items,
        ).toJson().containsKey('oldGoldValue'),
        isFalse,
      );
      expect(
        InvoiceDraft(
          customerName: 'Walk In',
          items: items,
          oldGoldValue: 0,
        ).toJson().containsKey('oldGoldValue'),
        isFalse,
      );
    });
  });

  group('InvoiceDraftItem', () {
    test('an inventory line sends only its id and quantity', () {
      const line = InvoiceDraftItem.inventory(
        inventoryItemId: 'item-1',
        quantity: 3,
      );
      final json = line.toJson();
      expect(line.isOnDemand, isFalse);
      expect(json['inventoryItemId'], 'item-1');
      expect(json['quantity'], 3);
      expect(json.containsKey('itemName'), isFalse);
      expect(json.containsKey('netWeight'), isFalse);
    });

    test('an on-demand line sends its own specs and no inventory id', () {
      const line = InvoiceDraftItem.onDemand(
        itemName: 'Custom ring',
        metalType: 'gold',
        karat: '22K',
        netWeight: 8.5,
        makingCharges: 1500,
      );
      final json = line.toJson();
      expect(line.isOnDemand, isTrue);
      expect(json.containsKey('inventoryItemId'), isFalse);
      expect(json['itemName'], 'Custom ring');
      expect(json['metalType'], 'gold');
      expect(json['karat'], '22K');
      expect(json['netWeight'], 8.5);
      expect(json['makingCharges'], 1500);
      expect(json['quantity'], 1);
    });

    test('an on-demand line omits making charges when not typed', () {
      const line = InvoiceDraftItem.onDemand(
        itemName: 'Custom bangle',
        metalType: 'gold',
        karat: '22K',
        netWeight: 4,
      );
      expect(line.toJson().containsKey('makingCharges'), isFalse);
    });

    test('inventory and on-demand lines ride on one bill', () {
      final draft = InvoiceDraft(
        customerName: 'Walk In',
        items: const [
          InvoiceDraftItem.inventory(inventoryItemId: 'a', quantity: 1),
          InvoiceDraftItem.onDemand(
            itemName: 'Custom ring',
            metalType: 'gold',
            karat: '22K',
            netWeight: 4,
          ),
        ],
      );
      final items = draft.toJson()['items'] as List;
      expect(items, hasLength(2));
      expect(items.first['inventoryItemId'], 'a');
      expect(items.last.containsKey('inventoryItemId'), isFalse);
      expect(items.last['itemName'], 'Custom ring');
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

    test('parses payments and flags an outstanding balance', () {
      final printable = PrintableInvoice.fromJson({
        'shop': {'name': 'S'},
        'invoice': {
          'invoiceNumber': 'SLK-2026-0002',
          'grandTotal': 10000,
          'amountPaid': 4000,
          'balanceDue': 6000,
          'payments': [
            {
              'id': 'p1',
              'amount': '4000',
              'paymentMode': 'upi',
              'referenceNumber': 'TXN-1',
              'paymentDate': '2026-06-11T00:00:00.000Z',
            },
          ],
        },
      });
      expect(printable.invoice.hasBalance, isTrue);
      expect(printable.invoice.payments, hasLength(1));
      expect(printable.invoice.payments.first.amount, 4000);
      expect(printable.invoice.payments.first.paymentMode, 'upi');
      expect(printable.invoice.payments.first.referenceNumber, 'TXN-1');
    });

    test('no balance when fully paid and no payments list', () {
      final printable = PrintableInvoice.fromJson({
        'invoice': {'grandTotal': 5000, 'amountPaid': 5000, 'balanceDue': 0},
      });
      expect(printable.invoice.hasBalance, isFalse);
      expect(printable.invoice.payments, isEmpty);
    });
  });

  group('BillingInventoryItem.fromJson (billing card fields)', () {
    test('parses photos, huid, status and exposes the first photo', () {
      final item = BillingInventoryItem.fromJson({
        'id': 'it1',
        'itemName': 'Gold Ring',
        'tagNumber': 'RG0004',
        'huid': '6HJ324AB',
        'metalType': 'gold',
        'karat': '22K',
        'stockType': 'unique',
        'status': 'in_stock',
        'netWeight': '6.420',
        'photos': ['data:image/png;base64,AAA', '', 'https://x/y.jpg'],
      });
      expect(item.huid, '6HJ324AB');
      expect(item.status, 'in_stock');
      // Empty strings are dropped from the photo list.
      expect(item.photos, ['data:image/png;base64,AAA', 'https://x/y.jpg']);
      expect(item.firstPhoto, 'data:image/png;base64,AAA');
      // HUID is searchable.
      expect(item.matches('6hj324'), isTrue);
    });

    test('safe defaults when photos/huid/status are missing', () {
      final item = BillingInventoryItem.fromJson({'id': 'it2'});
      expect(item.photos, isEmpty);
      expect(item.firstPhoto, isNull);
      expect(item.huid, isNull);
      expect(item.status, 'in_stock');
    });
  });

  group('BillingCustomerOption.fromJson (relationship stats)', () {
    test('parses denormalized stats and builds a location line', () {
      final c = BillingCustomerOption.fromJson({
        'id': 'c1',
        'name': 'Ramesh',
        'phone': '9876543210',
        'address': 'Dombivli',
        'city': 'Maharashtra',
        'totalPurchases': '245000',
        'totalVisits': 12,
        'lastVisitAt': '2024-05-12T00:00:00.000Z',
      });
      expect(c.totalPurchases, 245000);
      expect(c.totalVisits, 12);
      expect(c.lastVisitAt, isNotNull);
      expect(c.location, 'Dombivli, Maharashtra');
    });

    test('location falls back and stats default to zero', () {
      final c = BillingCustomerOption.fromJson({'id': 'c2', 'name': 'Asha'});
      expect(c.location, isNull);
      expect(c.totalPurchases, 0);
      expect(c.totalVisits, 0);
      expect(c.lastVisitAt, isNull);
    });
  });

  group('billingMoneyGrouped', () {
    test('applies Indian digit grouping', () {
      expect(billingMoneyGrouped(131485), '₹1,31,485');
      expect(billingMoneyGrouped(1000000), '₹10,00,000');
      expect(billingMoneyGrouped(12345), '₹12,345');
      expect(billingMoneyGrouped(500), '₹500');
      expect(billingMoneyGrouped(0), '₹0');
    });
  });
}
