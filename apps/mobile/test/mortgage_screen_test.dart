import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/mortgage/application/mortgage_providers.dart';
import 'package:swarnbook/features/mortgage/data/models/mortgage_loan.dart';
import 'package:swarnbook/features/mortgage/presentation/screens/collect_payment_page.dart';
import 'package:swarnbook/features/mortgage/presentation/screens/mortgage_form_page.dart';
import 'package:swarnbook/features/mortgage/presentation/screens/mortgage_screen.dart';
import 'package:swarnbook/l10n/app_localizations.dart';

Widget _host(Widget home, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

MortgageLoan _loan({String status = 'active'}) => MortgageLoan.fromJson({
  'id': 'l1',
  'loanNumber': 'ML-001',
  'status': status,
  'customerName': 'Asha',
  'principalAmount': 50000,
  'outstandingPrincipal': 30000,
  'pendingInterestAmount': 1200,
});

void main() {
  group('MortgageScreen', () {
    testWidgets('renders loan rows from the loans provider', (tester) async {
      await tester.pumpWidget(
        _host(
          const Scaffold(body: MortgageScreen()),
          overrides: [
            mortgageDashboardProvider.overrideWith(
              (ref) async => MortgageDashboard.empty,
            ),
            mortgageLoansProvider.overrideWith((ref, query) async => [_loan()]),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('ML-001'), findsOneWidget);
      expect(find.textContaining('Asha'), findsWidgets);
    });

    testWidgets('shows empty state when there are no loans', (tester) async {
      await tester.pumpWidget(
        _host(
          const Scaffold(body: MortgageScreen()),
          overrides: [
            mortgageDashboardProvider.overrideWith(
              (ref) async => MortgageDashboard.empty,
            ),
            mortgageLoansProvider.overrideWith((ref, query) async => []),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('No mortgage loans found'), findsOneWidget);
    });
  });

  group('Mortgage forms', () {
    testWidgets('create loan blocks save when required fields are empty', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const MortgageFormPage()));
      await tester.pump();

      await tester.tap(find.text('Save Loan'));
      await tester.pump();

      // Still on the form; a required validation is shown.
      expect(find.byType(MortgageFormPage), findsOneWidget);
      expect(find.text('Required'), findsWidgets);
    });

    testWidgets('collect payment blocks save when amount is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const CollectPaymentPage(loanId: 'l1')));
      await tester.pump();

      await tester.tap(find.text('Save Payment'));
      await tester.pump();

      expect(find.byType(CollectPaymentPage), findsOneWidget);
      expect(find.text('Required'), findsWidgets);
    });
  });
}
