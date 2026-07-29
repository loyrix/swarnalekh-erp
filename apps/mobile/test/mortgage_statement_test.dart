import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/mortgage/data/models/mortgage_loan.dart';
import 'package:swarnbook/features/mortgage/presentation/mortgage_statement.dart';

void main() {
  test('mortgageStatementTable maps the ledger with debit/credit + totals', () {
    final loan = MortgageLoan.fromJson({
      'id': 'l1',
      'loanNumber': 'ML-2026-0001',
      'customerName': 'Aman',
      'customerPhone': '1230098765',
      'loanDate': '2026-06-26',
      'interestRateMonthly': 2,
      'outstandingPrincipal': 50000,
      'totalPayableAmount': 50800,
    });
    final events = [
      const MortgageLedgerEvent(
        date: '2026-06-26',
        type: 'loan_created',
        amount: 40000,
        direction: 'debit',
      ),
      const MortgageLedgerEvent(
        date: '2026-07-10',
        type: 'topup_added',
        amount: 10000,
        direction: 'debit',
      ),
      const MortgageLedgerEvent(
        date: '2026-07-15',
        type: 'interest_collected',
        amount: 800,
        direction: 'credit',
      ),
    ];

    final table = mortgageStatementTable(loan, events);
    expect(table.title, 'Loan Statement · ML-2026-0001');
    expect(table.columns.length, 4);
    expect(table.rows.length, 3);
    // Loan disbursal is a debit; interest a credit.
    expect(table.rows[0][2], 'Rs. 40,000.00'); // debit column
    expect(table.rows[0][3], ''); // credit column empty
    expect(table.rows[2][3], 'Rs. 800.00'); // interest credit
    // Totals row: debit 50,000, credit 800.
    expect(table.totalRow, ['', 'Total', 'Rs. 50,000.00', 'Rs. 800.00']);
  });
}
