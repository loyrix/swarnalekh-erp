import 'package:swarnbook/features/mortgage/data/models/mortgage_loan.dart';
import 'package:swarnbook/features/reports/presentation/report_pdf_tables.dart';

String _money(double v) {
  final s = v.toStringAsFixed(2);
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
    grouped = '$rest$buf,$last3';
  }
  return '${neg ? '-' : ''}Rs. $grouped.${parts[1]}';
}

String _date(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';
  final d = DateTime.tryParse(raw.trim());
  if (d == null) return raw.trim();
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/'
      '${l.month.toString().padLeft(2, '0')}/${l.year}';
}

String _particulars(String type) => switch (type) {
  'loan_created' => 'Loan Disbursed',
  'topup_added' => 'Top-up Added',
  'interest_collected' => 'Interest Collected',
  'principal_collected' => 'Principal Collected',
  'closed' => 'Loan Closed / Settlement',
  _ => type,
};

/// Builds the printable loan-statement table (ledger as Date · Particulars ·
/// Debit · Credit, with a totals row) reusing the report PDF engine.
ReportPdfTable mortgageStatementTable(
  MortgageLoan loan,
  List<MortgageLedgerEvent> events,
) {
  final rows = events
      .map(
        (e) => [
          _date(e.date),
          _particulars(e.type),
          e.isCredit ? '' : _money(e.amount),
          e.isCredit ? _money(e.amount) : '',
        ],
      )
      .toList();

  final debit = events
      .where((e) => !e.isCredit)
      .fold<double>(0, (s, e) => s + e.amount);
  final credit = events
      .where((e) => e.isCredit)
      .fold<double>(0, (s, e) => s + e.amount);

  final summary = [
    'Customer: ${loan.customerName ?? '-'}',
    if (loan.customerPhone != null) loan.customerPhone!,
    'Loan Date: ${_date(loan.loanDate)}',
    'Rate: ${loan.interestRateMonthly}% p.m.',
    'Outstanding: ${_money(loan.outstandingPrincipal)}',
    'Total Payable: ${_money(loan.totalPayableAmount)}',
  ].join('  ·  ');

  return ReportPdfTable(
    title: 'Loan Statement · ${loan.loanNumber ?? ''}',
    summary: summary,
    columns: const [
      ReportPdfColumn('Date', flex: 2),
      ReportPdfColumn('Particulars', flex: 4),
      ReportPdfColumn('Debit', flex: 2, numeric: true),
      ReportPdfColumn('Credit', flex: 2, numeric: true),
    ],
    rows: rows,
    totalRow: ['', 'Total', _money(debit), _money(credit)],
  );
}
