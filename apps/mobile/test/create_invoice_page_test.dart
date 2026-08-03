import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/billing/presentation/screens/create_invoice_page.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_state_view.dart';

Widget _host(Widget home) => ProviderScope(
  child: MaterialApp(
    theme: buildLightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  group('CreateInvoicePage', () {
    // The form data load hits the network, which is unavailable under test, so
    // the page settles into its error state. That still exercises mount and
    // dispose of the whole route — the lifecycle path that used to blow up.
    testWidgets('mounts and disposes cleanly without a framework assertion', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const CreateInvoicePage()));
      await tester.pumpAndSettle();

      expect(find.byType(CreateInvoicePage), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tear the route down: disposing the page's controllers while the route
      // unwinds must not trip '_dependents.isEmpty'.
      await tester.pumpWidget(_host(const SizedBox.shrink()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('offers a retry when the form data cannot be loaded', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const CreateInvoicePage()));
      await tester.pumpAndSettle();

      // Error state is one of the four required UI states.
      expect(find.byType(AppErrorView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
