import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/reports/data/models/reports_data.dart';
import 'package:swarnbook/features/reports/data/reports_repository.dart';

void main() {
  group('ReportsData.fromJson', () {
    test('parses every report list and inventory stats', () {
      final data = ReportsData.fromJson({
        'inventoryStats': {'totalGoldWeight': '120.5', 'totalSilverWeight': 40},
        'reports': {
          'currentStock': [
            {
              'itemName': 'Ring',
              'categoryName': 'Ring',
              'barcode': 'B1',
              'status': 'in_stock',
              'karat': '22K',
              'grossWeight': 5,
              'netWeight': '4.2',
              'estimatedSellingPrice': '32000',
              'location': 'Main',
            },
          ],
          'soldProducts': [
            {
              'productName': 'Chain',
              'invoiceNumber': 'INV-1',
              'customerName': 'Asha',
              'sellingPrice': 15000,
              'soldDate': '2026-06-30',
              'paymentMode': 'cash',
            },
          ],
          'lowStock': [
            {'itemName': 'Stud', 'quantity': 1, 'karat': '18K'},
          ],
          'dailySales': [
            {
              'invoiceNumber': 'INV-2',
              'grandTotal': '5000',
              'items': [
                {'x': 1},
                {'x': 2},
              ],
            },
          ],
          'monthlySales': [
            {'invoiceNumber': 'INV-3', 'grandTotal': 9000},
          ],
          'gst': [
            {'invoiceNumber': 'INV-4', 'taxableAmount': 1000, 'totalTax': 30},
          ],
          'activeLoans': [
            {
              'loanNumber': 'ML-1',
              'principalAmount': 50000,
              'pendingInterestAmount': 1200,
            },
          ],
          'interestCollection': [
            {
              'receiptNumber': 'R-1',
              'amount': '1200',
              'paymentType': 'interest',
            },
          ],
          'closedLoans': [
            {
              'loanNumber': 'ML-9',
              'status': 'closed',
              'totalInterestPaid': 4000,
            },
          ],
        },
      });

      expect(data.totalGoldWeight, 120.5);
      expect(data.currentStock, hasLength(1));
      expect(data.currentStock.first.netWeight, 4.2);
      expect(data.currentStock.first.designTag, 'B1');
      expect(data.soldProducts.first.sellingPrice, 15000);
      expect(data.lowStock.first.quantity, 1);
      expect(data.dailySales.first.itemCount, 2);
      expect(data.monthlySales.first.grandTotal, 9000);
      expect(data.gst.first.totalTax, 30);
      expect(data.activeLoans.first.pendingInterestAmount, 1200);
      expect(data.interestCollection.first.amount, 1200);
      expect(data.closedLoans.first.totalInterestPaid, 4000);
    });

    test('tolerates an empty payload', () {
      final data = ReportsData.fromJson(const {});
      expect(data.currentStock, isEmpty);
      expect(data.gst, isEmpty);
      expect(data.totalGoldWeight, 0);
    });
  });

  group('ReportsQuery', () {
    test('returns null parameters when all filters are empty', () {
      expect(const ReportsQuery().toQueryParameters(), isNull);
    });

    test('includes set filters and omits status=all', () {
      const q = ReportsQuery(
        search: 'asha',
        dateFrom: '2026-06-01',
        category: 'Ring',
        status: 'all',
      );
      final params = q.toQueryParameters()!;
      expect(params['search'], 'asha');
      expect(params['dateFrom'], '2026-06-01');
      expect(params['categoryName'], 'Ring');
      expect(params.containsKey('status'), isFalse);
    });

    test('value equality keys the provider family', () {
      const a = ReportsQuery(status: 'sold');
      final b = const ReportsQuery().copyWith(status: 'sold');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
