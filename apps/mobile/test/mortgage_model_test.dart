import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/mortgage/data/models/mortgage_loan.dart';
import 'package:swarnbook/features/mortgage/data/mortgage_repository.dart';
import 'package:swarnbook/features/mortgage/presentation/mortgage_format.dart';

void main() {
  group('MortgageLoan.fromJson', () {
    test('parses typed fields, ornaments, and payments', () {
      final loan = MortgageLoan.fromJson({
        'id': 'l1',
        'loanNumber': 'ML-1',
        'status': 'active',
        'customerName': 'Asha',
        'customerPhone': '99999',
        'principalAmount': '50000',
        'outstandingPrincipal': 30000,
        'pendingInterestAmount': '1200',
        'totalPayableAmount': 31200,
        'interestRateMonthly': '2',
        'aadhaarNumber': '1234',
        'ornaments': [
          {
            'ornamentType': 'Chain',
            'purity': '22K',
            'grossWeight': 10,
            'netWeight': '9.5',
          },
        ],
        'payments': [
          {'id': 'p1', 'amount': '1200', 'receiptNumber': 'RCPT-1'},
        ],
      });

      expect(loan.id, 'l1');
      expect(loan.isActive, isTrue);
      expect(loan.principalAmount, 50000);
      expect(loan.outstandingPrincipal, 30000);
      expect(loan.pendingInterestAmount, 1200);
      expect(loan.ornaments, hasLength(1));
      expect(loan.ornaments.first.netWeight, 9.5);
      expect(loan.payments, hasLength(1));
      expect(loan.payments.first.amount, 1200);
      expect(loan.payments.first.receiptNumber, 'RCPT-1');
    });

    test('defaults are safe when fields are missing', () {
      final loan = MortgageLoan.fromJson({'id': 'x'});
      expect(loan.status, 'active');
      expect(loan.principalAmount, 0);
      expect(loan.ornaments, isEmpty);
      expect(loan.payments, isEmpty);
      expect(loan.customerName, isNull);
    });

    test('closed loans report isActive false', () {
      final loan = MortgageLoan.fromJson({'id': 'x', 'status': 'closed'});
      expect(loan.isActive, isFalse);
    });

    test('parses loanDate and interestMonths', () {
      final loan = MortgageLoan.fromJson({
        'id': 'x',
        'loanDate': '2026-01-10T00:00:00.000Z',
        'interestMonths': 2,
      });
      expect(loan.loanDate, '2026-01-10T00:00:00.000Z');
      expect(loan.interestMonths, 2);
    });
  });

  group('mortgageTenure', () {
    test('renders elapsed years, months and days compactly', () {
      final tenure = mortgageTenure(
        '2025-01-10T00:00:00.000Z',
        asOf: DateTime.utc(2026, 3, 15),
      );
      expect(tenure, '1y 2m 5d');
    });

    test('drops zero leading parts but always shows something', () {
      expect(
        mortgageTenure(
          '2026-01-10T00:00:00.000Z',
          asOf: DateTime.utc(2026, 1, 10),
        ),
        '0d',
      );
      expect(
        mortgageTenure(
          '2026-01-10T00:00:00.000Z',
          asOf: DateTime.utc(2026, 2, 12),
        ),
        '1m 2d',
      );
    });

    test('returns a dash when the loan date is missing', () {
      expect(mortgageTenure(null), '-');
    });
  });

  group('MortgageDashboard.fromJson', () {
    test('parses counters and money', () {
      final d = MortgageDashboard.fromJson({
        'activeLoans': 3,
        'closedLoans': '5',
        'pendingInterest': '2400',
        'totalLoanAmount': 500000,
        'todaysCollections': '1500',
        'overdueLoans': 1,
      });
      expect(d.activeLoans, 3);
      expect(d.closedLoans, 5);
      expect(d.pendingInterest, 2400);
      expect(d.overdueLoans, 1);
    });
  });

  group('MortgageQuery', () {
    test('omits status=all and empty search from parameters', () {
      const q = MortgageQuery(status: 'all');
      expect(q.toQueryParameters().containsKey('status'), isFalse);
      expect(q.toQueryParameters().containsKey('search'), isFalse);
    });

    test('includes status and trimmed search', () {
      const q = MortgageQuery(status: 'active', search: '  asha ');
      final params = q.toQueryParameters();
      expect(params['status'], 'active');
      expect(params['search'], 'asha');
    });

    test('value equality keys the provider family', () {
      const a = MortgageQuery(status: 'closed');
      final b = const MortgageQuery().copyWith(status: 'closed');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
