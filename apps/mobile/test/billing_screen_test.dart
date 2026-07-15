import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/billing/application/invoice_providers.dart';
import 'package:swarnbook/features/billing/data/models/invoice.dart';
import 'package:swarnbook/features/billing/presentation/screens/billing_screen.dart';
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

BillingDashboard _dashboard() => BillingDashboard.fromJson({
  'todaysRevenue': 1200,
  'monthlyRevenue': 45000,
  'totalBills': 12,
  'averageBillValue': 3750,
  'topSellingProducts': [
    {'itemName': 'Ring', 'quantity': 5},
  ],
});

Invoice _invoice() => Invoice.fromJson({
  'id': 'i1',
  'invoiceNumber': 'SLK-2026-0001',
  'customerName': 'Asha',
  'grandTotal': 15000,
  'amountPaid': 10000,
  'balanceDue': 5000,
  'items': [
    {'id': 'a'},
  ],
});

void main() {
  group('BillingScreen', () {
    testWidgets('shows dashboard stats without a top-selling section', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Scaffold(body: BillingScreen()),
          overrides: [
            billingDashboardProvider.overrideWith((ref) async => _dashboard()),
            invoicesProvider.overrideWith((ref, query) async => []),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text("Today's Revenue"), findsOneWidget);
      // Top Selling Products was removed from the billing dashboard.
      expect(find.text('Top Selling Products'), findsNothing);
    });

    testWidgets('history section lists invoices from the provider', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Scaffold(body: BillingScreen()),
          overrides: [
            billingDashboardProvider.overrideWith((ref) async => _dashboard()),
            invoicesProvider.overrideWith((ref, query) async => [_invoice()]),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Invoice History'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('SLK-2026-0001'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
    });

    testWidgets('history section shows empty state when there are none', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Scaffold(body: BillingScreen()),
          overrides: [
            billingDashboardProvider.overrideWith((ref) async => _dashboard()),
            invoicesProvider.overrideWith((ref, query) async => []),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Invoice History'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(BillingScreen), findsOneWidget);
      expect(find.text('SLK-2026-0001'), findsNothing);
    });
  });
}
