import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/inventory/data/inventory_repository.dart';
import 'package:swarnbook/features/inventory/data/models/inventory_item.dart';
import 'package:swarnbook/shared/application/stat_period.dart';

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
        categoryId: 'cat-ring',
        branch: 'Main',
        dateFrom: '2026-06-01',
        dateTo: '2026-06-30',
      );
      final params = query.toQueryParameters();
      expect(params['metalType'], 'gold');
      expect(params['search'], 'ring');
      expect(params['categoryId'], 'cat-ring');
      expect(params['location'], 'Main');
      expect(params['dateFrom'], '2026-06-01');
      expect(params['dateTo'], '2026-06-30');
    });

    test('SoldQuery maps period presets and custom ranges to params', () {
      const monthly = SoldQuery(search: ' ring ', period: StatPeriod.month);
      final monthParams = monthly.toQueryParameters();
      expect(monthParams['search'], 'ring');
      expect(monthParams['period'], 'month');

      final custom = SoldQuery(
        period: StatPeriod(
          StatPeriodKind.custom,
          range: DateTimeRange(
            start: DateTime(2026, 6, 1),
            end: DateTime(2026, 6, 30),
          ),
        ),
      );
      final customParams = custom.toQueryParameters();
      expect(customParams['period'], 'custom');
      expect(customParams['dateFrom'], '2026-06-01');
      expect(customParams['dateTo'], '2026-06-30');
    });

    test('SoldProduct parses the richer sold row payload', () {
      final row = SoldProduct.fromJson(const {
        'productName': 'Gold Ring',
        'invoiceNumber': 'SLK-2026-0001',
        'customerName': 'Priya',
        'soldDate': '2026-06-10T00:00:00.000Z',
        'sellingPrice': 58100,
        'paymentMethod': 'upi',
        'tagNumber': 'RG-04',
        'categoryName': 'Ring',
        'metalType': 'gold',
        'karat': '22K',
        'netWeight': 4.2,
      });
      expect(row.tagNumber, 'RG-04');
      expect(row.categoryName, 'Ring');
      expect(row.karat, '22K');
      expect(row.netWeight, 4.2);
    });

    test('InventoryStats parses metal and karat breakdowns', () {
      final stats = InventoryStats.fromJson(const {
        'totalProducts': 3,
        'metalBreakdown': [
          {'metalType': 'gold', 'count': 2, 'quantity': 2, 'totalWeight': 20},
        ],
        'karatBreakdown': [
          {
            'metalType': 'gold',
            'karats': [
              {'karat': '22K', 'count': 1, 'totalWeight': 10.5},
            ],
          },
        ],
      });
      expect(stats.metalBreakdown.single.metalType, 'gold');
      expect(stats.metalBreakdown.single.count, 2);
      expect(stats.karatBreakdown.single.karats.single.karat, '22K');
      expect(stats.karatBreakdown.single.karats.single.totalWeight, 10.5);
    });

    test('value equality keys the provider family', () {
      const a = InventoryQuery(metal: 'gold');
      final b = const InventoryQuery().copyWith(metal: 'gold');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
