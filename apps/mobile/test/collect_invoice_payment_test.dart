import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/billing/presentation/screens/collect_invoice_payment_page.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';

Widget _host(Widget home) => ProviderScope(
  child: MaterialApp(
    theme: buildLightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  group('CollectInvoicePaymentPage', () {
    testWidgets('prefills the outstanding balance as the default amount', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CollectInvoicePaymentPage(
            invoiceId: 'inv-1',
            invoiceNumber: 'SLK-2026-0001',
            balanceDue: 6000,
          ),
        ),
      );
      await tester.pump();

      expect(find.widgetWithText(TextFormField, '6000'), findsOneWidget);
    });

    testWidgets('blocks a payment greater than the balance due', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CollectInvoicePaymentPage(
            invoiceId: 'inv-1',
            invoiceNumber: 'SLK-2026-0001',
            balanceDue: 6000,
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, '9000');
      await tester.ensureVisible(find.byType(GoldButton).last);
      await tester.tap(find.byType(GoldButton).last);
      await tester.pump();

      // Still on the form — the over-balance validation blocked the save.
      expect(find.byType(CollectInvoicePaymentPage), findsOneWidget);
      expect(find.textContaining('Balance'), findsWidgets);
    });
  });
}
