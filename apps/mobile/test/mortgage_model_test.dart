import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/features/mortgage/data/models/mortgage_loan.dart';
import 'package:swarnbook/features/mortgage/data/mortgage_repository.dart';

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
