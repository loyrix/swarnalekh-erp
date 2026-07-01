import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/inventory/data/inventory_repository.dart';
import 'package:swarnbook/features/inventory/data/models/inventory_item.dart';

void main() {
  group('InventoryItem.fromJson', () {
    test('reads typed fields, nested category, and first photo', () {
      final item = InventoryItem.fromJson({
        'id': 'i1',
        'itemName': 'Gold Ring',
        'tagNumber': 'T-1',
        'barcode': 'B-9',
        'category': {'name': 'Ring'},
        'metalType': 'gold',
        'karat': '22K',
        'netWeight': '4.2',
        'grossWeight': 5,
        'estimatedSellingPrice': '32000',
        'quantity': '2',
        'photos': ['data:image/png;base64,AAAA', 'x'],
        'status': 'in_stock',
      });

      expect(item.id, 'i1');
      expect(item.itemName, 'Gold Ring');
      expect(item.categoryName, 'Ring');
      // designNumber falls back to barcode when designNumber absent.
      expect(item.designNumber, 'B-9');
      expect(item.karat, '22K');
      expect(item.netWeight, 4.2);
      expect(item.grossWeight, 5);
      expect(item.estimatedSellingPrice, 32000);
      expect(item.quantity, 2);
      expect(item.photo, 'data:image/png;base64,AAAA');
    });

    test('defaults are safe when fields are missing', () {
      final item = InventoryItem.fromJson({'id': 'x'});
      expect(item.itemName, isNull);
      expect(item.metalType, 'gold');
      expect(item.stockType, 'unique');
      expect(item.status, 'in_stock');
      expect(item.quantity, 1);
      expect(item.netWeight, isNull);
      expect(item.photo, isNull);
    });

    test('accepts a string photos field', () {
      final item = InventoryItem.fromJson({
        'id': 'x',
        'photos': 'http://a/b.png',
      });
      expect(item.photo, 'http://a/b.png');
    });
  });

  group('InventoryStats.fromJson', () {
    test('flattens the alerts block into counts', () {
      final stats = InventoryStats.fromJson({
        'totalGoldWeight': '120.5',
        'totalProducts': 8,
        'soldThisMonth': 3,
        'alerts': {'lowStock': 2, 'outOfStock': 0, 'highValueProducts': '1'},
        'valuationDate': '2026-07-01',
      });
      expect(stats.totalGoldWeight, 120.5);
      expect(stats.totalProducts, 8);
      expect(stats.lowStock, 2);
      expect(stats.outOfStock, 0);
      expect(stats.highValueProducts, 1);
      expect(stats.valuationDate, '2026-07-01');
    });
  });

  group('InventoryOverview.fromJson', () {
    test('parses items and stats', () {
      final overview = InventoryOverview.fromJson({
        'items': [
          {'id': 'a', 'itemName': 'A'},
          {'id': 'b', 'itemName': 'B'},
        ],
        'stats': {'totalProducts': 2},
      });
      expect(overview.items, hasLength(2));
      expect(overview.stats?.totalProducts, 2);
    });

    test('tolerates a missing stats block', () {
      final overview = InventoryOverview.fromJson({'items': []});
      expect(overview.items, isEmpty);
      expect(overview.stats, isNull);
    });
  });

  group('SoldProduct.fromJson', () {
    test('parses sold row fields', () {
      final sold = SoldProduct.fromJson({
        'productName': 'Chain',
        'invoiceNumber': 'INV-1',
        'customerName': 'Asha',
        'soldDate': '2026-06-30T00:00:00.000Z',
        'sellingPrice': '15000',
        'paymentMethod': 'bank_transfer',
      });
      expect(sold.productName, 'Chain');
      expect(sold.invoiceNumber, 'INV-1');
      expect(sold.sellingPrice, 15000);
      expect(sold.paymentMethod, 'bank_transfer');
    });
  });

  group('InventoryQuery', () {
    test('omits metal=all and empty filters from query parameters', () {
      const query = InventoryQuery(status: 'in_stock', metal: 'all');
      final params = query.toQueryParameters();
      expect(params['status'], 'in_stock');
      expect(params.containsKey('metalType'), isFalse);
      expect(params.containsKey('search'), isFalse);
    });

    test('includes set filters and trims search', () {
      const query = InventoryQuery(
        status: 'sold',
        metal: 'gold',
        search: '  ring ',
        category: 'Ring',
        branch: 'Main',
      );
      final params = query.toQueryParameters();
      expect(params['metalType'], 'gold');
      expect(params['search'], 'ring');
      expect(params['categoryName'], 'Ring');
      expect(params['location'], 'Main');
    });

    test('value equality keys the provider family', () {
      const a = InventoryQuery(metal: 'gold');
      final b = const InventoryQuery().copyWith(metal: 'gold');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
