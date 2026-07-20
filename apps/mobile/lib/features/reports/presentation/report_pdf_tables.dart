import 'package:swarnbook/features/reports/data/models/reports_data.dart';

/// One column in a report PDF table.
class ReportPdfColumn {
  const ReportPdfColumn(this.label, {this.flex = 1, this.numeric = false});

  final String label;

  /// Relative width of the column.
  final int flex;

  /// Right-aligns the cell (money / weight / counts read better flush-right).
  final bool numeric;
}

/// A fully-resolved report table: heading, columns, string rows, and an
/// optional summary row rendered as an emphasised footer. Pure data — no
/// Flutter or `pdf` types — so it is unit-testable on its own.
class ReportPdfTable {
  const ReportPdfTable({
    required this.title,
    required this.columns,
    required this.rows,
    this.summary,
    this.totalRow,
  });

  final String title;
  final List<ReportPdfColumn> columns;
  final List<List<String>> rows;

  /// One-line context under the title (date range, totals in prose, etc.).
  final String? summary;

  /// Optional emphasised footer row (must match `columns.length`).
  final List<String>? totalRow;
}

String _money(double v) {
  final s = v.toStringAsFixed(2);
  // Indian grouping (##,##,###.##) keeps large sums readable on the page.
  final parts = s.split('.');
  var intPart = parts[0];
  final neg = intPart.startsWith('-');
  if (neg) intPart = intPart.substring(1);
  String grouped;
  if (intPart.length <= 3) {
    grouped = intPart;
  } else {
    final last3 = intPart.substring(intPart.length - 3);
    var rest = intPart.substring(0, intPart.length - 3);
    final buf = StringBuffer();
    while (rest.length > 2) {
      buf.write(',${rest.substring(rest.length - 2)}');
      rest = rest.substring(0, rest.length - 2);
    }
    grouped = '$rest${buf.toString()},$last3';
  }
  return '${neg ? '-' : ''}Rs. $grouped.${parts[1]}';
}

String _weight(double v) => '${v.toStringAsFixed(3)} g';

String _val(String? v, [String fallback = '-']) {
  final s = v?.trim();
  return (s == null || s.isEmpty) ? fallback : s;
}

String _date(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';
  final d = DateTime.tryParse(raw.trim());
  if (d == null) return raw.trim();
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/'
      '${l.month.toString().padLeft(2, '0')}/${l.year}';
}

String _titleCase(String? raw) {
  final s = raw?.trim();
  if (s == null || s.isEmpty) return '-';
  return s
      .replaceAll('_', ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Builds the table for a given `/reports/export/:reportType` id from the
/// already-loaded overview data. Returns `null` for an unknown type.
ReportPdfTable? buildReportPdfTable(String reportType, ReportsData data) {
  switch (reportType) {
    case 'current-stock':
      final rows = data.currentStock
          .map(
            (i) => [
              _val(i.itemName),
              _val(i.categoryName),
              _val(i.designTag),
              _val(i.karatOrPurity),
              _weight(i.grossWeight),
              _weight(i.netWeight),
              _titleCase(i.status),
              _money(i.sellingPrice),
            ],
          )
          .toList();
      final totalValue = data.currentStock.fold<double>(
        0,
        (s, i) => s + i.sellingPrice,
      );
      return ReportPdfTable(
        title: 'Current Stock Report',
        summary:
            '${data.currentStock.length} items in stock  ·  '
            'Gold ${_weight(data.totalGoldWeight)}  ·  '
            'Silver ${_weight(data.totalSilverWeight)}',
        columns: const [
          ReportPdfColumn('Product', flex: 3),
          ReportPdfColumn('Category', flex: 2),
          ReportPdfColumn('Tag', flex: 2),
          ReportPdfColumn('Purity'),
          ReportPdfColumn('Gross', numeric: true),
          ReportPdfColumn('Net', numeric: true),
          ReportPdfColumn('Status'),
          ReportPdfColumn('Est. Value', flex: 2, numeric: true),
        ],
        rows: rows,
        totalRow: ['Total', '', '', '', '', '', '', _money(totalValue)],
      );

    case 'sold-products':
      final rows = data.soldProducts
          .map(
            (i) => [
              _val(i.productName),
              _val(i.invoiceNumber),
              _val(i.customerName),
              _titleCase(i.paymentMode),
              _date(i.soldDate),
              _money(i.sellingPrice),
            ],
          )
          .toList();
      final total = data.soldProducts.fold<double>(
        0,
        (s, i) => s + i.sellingPrice,
      );
      return ReportPdfTable(
        title: 'Sold Products Report',
        summary: '${data.soldProducts.length} items sold',
        columns: const [
          ReportPdfColumn('Product', flex: 3),
          ReportPdfColumn('Invoice', flex: 2),
          ReportPdfColumn('Customer', flex: 2),
          ReportPdfColumn('Mode'),
          ReportPdfColumn('Date'),
          ReportPdfColumn('Price', flex: 2, numeric: true),
        ],
        rows: rows,
        totalRow: ['Total', '', '', '', '', _money(total)],
      );

    case 'low-stock':
      final rows = data.lowStock
          .map(
            (i) => [
              _val(i.itemName),
              _val(i.categoryName),
              _val(i.designTag),
              _val(i.karatOrPurity),
              '${i.quantity}',
              _val(i.location, 'Main'),
            ],
          )
          .toList();
      return ReportPdfTable(
        title: 'Low Stock Report',
        summary: '${data.lowStock.length} items at or below threshold',
        columns: const [
          ReportPdfColumn('Product', flex: 3),
          ReportPdfColumn('Category', flex: 2),
          ReportPdfColumn('Tag', flex: 2),
          ReportPdfColumn('Purity'),
          ReportPdfColumn('Qty', numeric: true),
          ReportPdfColumn('Branch', flex: 2),
        ],
        rows: rows,
      );

    case 'daily-sales':
    case 'monthly-sales':
      final sales = reportType == 'daily-sales'
          ? data.dailySales
          : data.monthlySales;
      final rows = sales
          .map(
            (i) => [
              _val(i.invoiceNumber),
              _val(i.customerName, 'Walk-in'),
              _date(i.invoiceDate),
              '${i.itemCount}',
              _titleCase(i.paymentMode),
              _money(i.grandTotal),
            ],
          )
          .toList();
      final total = sales.fold<double>(0, (s, i) => s + i.grandTotal);
      return ReportPdfTable(
        title: reportType == 'daily-sales'
            ? 'Daily Sales Report'
            : 'Monthly Sales Report',
        summary: '${sales.length} invoices',
        columns: const [
          ReportPdfColumn('Invoice', flex: 2),
          ReportPdfColumn('Customer', flex: 3),
          ReportPdfColumn('Date', flex: 2),
          ReportPdfColumn('Items', numeric: true),
          ReportPdfColumn('Mode'),
          ReportPdfColumn('Total', flex: 2, numeric: true),
        ],
        rows: rows,
        totalRow: ['Total', '', '', '', '', _money(total)],
      );

    case 'gst':
      final rows = data.gst
          .map(
            (i) => [
              _val(i.invoiceNumber),
              _val(i.customerName, 'Walk-in'),
              _money(i.taxableAmount),
              _money(i.cgstAmount),
              _money(i.sgstAmount),
              _money(i.totalTax),
            ],
          )
          .toList();
      final taxable = data.gst.fold<double>(0, (s, i) => s + i.taxableAmount);
      final cgst = data.gst.fold<double>(0, (s, i) => s + i.cgstAmount);
      final sgst = data.gst.fold<double>(0, (s, i) => s + i.sgstAmount);
      final tax = data.gst.fold<double>(0, (s, i) => s + i.totalTax);
      return ReportPdfTable(
        title: 'GST Report',
        summary: '${data.gst.length} taxable invoices',
        columns: const [
          ReportPdfColumn('Invoice', flex: 2),
          ReportPdfColumn('Customer', flex: 3),
          ReportPdfColumn('Taxable', flex: 2, numeric: true),
          ReportPdfColumn('CGST', numeric: true),
          ReportPdfColumn('SGST', numeric: true),
          ReportPdfColumn('Total Tax', flex: 2, numeric: true),
        ],
        rows: rows,
        totalRow: [
          'Total',
          '',
          _money(taxable),
          _money(cgst),
          _money(sgst),
          _money(tax),
        ],
      );

    case 'active-loans':
      final rows = data.activeLoans
          .map(
            (i) => [
              _val(i.customerName),
              _val(i.loanNumber),
              _money(i.principalAmount),
              _money(i.pendingInterestAmount),
              _money(i.totalPayableAmount),
              _date(i.nextDueDate),
            ],
          )
          .toList();
      final principal = data.activeLoans.fold<double>(
        0,
        (s, i) => s + i.principalAmount,
      );
      final payable = data.activeLoans.fold<double>(
        0,
        (s, i) => s + i.totalPayableAmount,
      );
      return ReportPdfTable(
        title: 'Active Loans Report',
        summary: '${data.activeLoans.length} active loans',
        columns: const [
          ReportPdfColumn('Customer', flex: 3),
          ReportPdfColumn('Loan No.', flex: 2),
          ReportPdfColumn('Principal', flex: 2, numeric: true),
          ReportPdfColumn('Pending Int.', flex: 2, numeric: true),
          ReportPdfColumn('Payable', flex: 2, numeric: true),
          ReportPdfColumn('Next Due', flex: 2),
        ],
        rows: rows,
        totalRow: ['Total', '', _money(principal), '', _money(payable), ''],
      );

    case 'interest-collection':
      final rows = data.interestCollection
          .map(
            (i) => [
              _val(i.receiptNumber),
              _val(i.customerName),
              _val(i.loanNumber),
              _titleCase(i.paymentType),
              _titleCase(i.paymentMode),
              _date(i.paymentDate),
              _money(i.amount),
            ],
          )
          .toList();
      final total = data.interestCollection.fold<double>(
        0,
        (s, i) => s + i.amount,
      );
      return ReportPdfTable(
        title: 'Interest Collection Report',
        summary: '${data.interestCollection.length} receipts',
        columns: const [
          ReportPdfColumn('Receipt', flex: 2),
          ReportPdfColumn('Customer', flex: 3),
          ReportPdfColumn('Loan No.', flex: 2),
          ReportPdfColumn('Type'),
          ReportPdfColumn('Mode'),
          ReportPdfColumn('Date', flex: 2),
          ReportPdfColumn('Amount', flex: 2, numeric: true),
        ],
        rows: rows,
        totalRow: ['Total', '', '', '', '', '', _money(total)],
      );

    case 'closed-loans':
      final rows = data.closedLoans
          .map(
            (i) => [
              _val(i.customerName),
              _val(i.loanNumber),
              _titleCase(i.status),
              _money(i.principalAmount),
              _money(i.totalInterestPaid),
              _date(i.closedAt),
            ],
          )
          .toList();
      final principal = data.closedLoans.fold<double>(
        0,
        (s, i) => s + i.principalAmount,
      );
      final interest = data.closedLoans.fold<double>(
        0,
        (s, i) => s + i.totalInterestPaid,
      );
      return ReportPdfTable(
        title: 'Closed Loans Report',
        summary: '${data.closedLoans.length} closed loans',
        columns: const [
          ReportPdfColumn('Customer', flex: 3),
          ReportPdfColumn('Loan No.', flex: 2),
          ReportPdfColumn('Status'),
          ReportPdfColumn('Principal', flex: 2, numeric: true),
          ReportPdfColumn('Interest Paid', flex: 2, numeric: true),
          ReportPdfColumn('Closed', flex: 2),
        ],
        rows: rows,
        totalRow: ['Total', '', '', _money(principal), _money(interest), ''],
      );
  }
  return null;
}
