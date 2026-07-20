import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/reports/data/models/reports_data.dart';
import 'package:swarnbook/features/reports/presentation/report_pdf.dart';
import 'package:swarnbook/features/reports/presentation/report_pdf_tables.dart';

bool _isPdf(List<int> bytes) =>
    bytes.length > 4 &&
    bytes[0] == 0x25 && // %
    bytes[1] == 0x50 && // P
    bytes[2] == 0x44 && // D
    bytes[3] == 0x46; // F

ReportsData _fixture() {
  return ReportsData.fromJson({
    'reports': {
      'currentStock': [
        {
          'itemName': 'Gold Ring',
          'categoryName': 'Ring',
          'tagNumber': 'RG-0001',
          'status': 'in_stock',
          'karat': '22K',
          'grossWeight': 10.5,
          'netWeight': 9.25,
          'estimatedSellingPrice': 59000,
          'quantity': 1,
        },
        {
          'itemName': 'Silver Anklet',
          'categoryName': 'Anklet',
          'tagNumber': 'AN-0002',
          'status': 'reserved',
          'purity': '925',
          'grossWeight': 40,
          'netWeight': 39,
          'estimatedSellingPrice': 8000,
          'quantity': 2,
        },
      ],
      'gst': [
        {
          'invoiceNumber': 'SLK-1',
          'customerName': 'Asha',
          'taxableAmount': 100000,
          'cgstAmount': 1500,
          'sgstAmount': 1500,
          'totalTax': 3000,
        },
      ],
    },
    'inventoryStats': {'totalGoldWeight': 9.25, 'totalSilverWeight': 39.0},
  });
}

void main() {
  group('buildReportPdfTable', () {
    test('builds a current-stock table with a summing total row', () {
      final table = buildReportPdfTable('current-stock', _fixture())!;
      expect(table.title, 'Current Stock Report');
      expect(table.rows.length, 2);
      expect(table.columns.length, 8);
      // Row cells match the column count.
      expect(table.rows.first.length, table.columns.length);
      // Total row sums the estimated value (59000 + 8000 = 67000).
      expect(table.totalRow, isNotNull);
      expect(table.totalRow!.last, 'Rs. 67,000.00');
      // Purity falls back to `purity` when `karat` is absent.
      expect(table.rows[1][3], '925');
      // Status is title-cased.
      expect(table.rows.first[6], 'In Stock');
    });

    test('builds a gst table totalling tax columns', () {
      final table = buildReportPdfTable('gst', _fixture())!;
      expect(table.title, 'GST Report');
      expect(table.rows.length, 1);
      expect(table.totalRow!.last, 'Rs. 3,000.00');
    });

    test('returns null for an unknown report type', () {
      expect(buildReportPdfTable('does-not-exist', _fixture()), isNull);
    });

    test('empty data still yields a table with no rows', () {
      final empty = ReportsData.fromJson(const {});
      final table = buildReportPdfTable('current-stock', empty)!;
      expect(table.rows, isEmpty);
    });
  });

  group('buildReportPdf', () {
    test('produces a valid, non-trivial PDF for a populated report', () async {
      final table = buildReportPdfTable('current-stock', _fixture())!;
      final bytes = await buildReportPdf(
        shop: const ReportPdfShop(
          name: 'Krishna Jewellers',
          address: 'MG Road, Ahmedabad',
          phone: '+91 99999 00000',
          gstin: '24ABCDE1234F1Z5',
        ),
        table: table,
        generatedAt: DateTime(2026, 7, 20, 10, 30),
      );
      expect(_isPdf(bytes), isTrue);
      expect(bytes.length, greaterThan(1000));
    });

    test('renders an empty-state PDF when there are no rows', () async {
      final empty = ReportsData.fromJson(const {});
      final table = buildReportPdfTable('sold-products', empty)!;
      final bytes = await buildReportPdf(
        shop: const ReportPdfShop(),
        table: table,
      );
      expect(_isPdf(bytes), isTrue);
    });
  });
}
