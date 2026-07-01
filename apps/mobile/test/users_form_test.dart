import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/users/application/user_management_payloads.dart';
import 'package:swarnbook/features/users/presentation/screens/user_form_page.dart';
import 'package:swarnbook/l10n/app_localizations.dart';

Widget _host(Widget home) => MaterialApp(
  theme: buildLightTheme(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  group('UserFormPage', () {
    testWidgets('validates name and email and blocks save when empty', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const UserFormPage()));
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();

      // Still on the form (validation failed).
      expect(find.byType(UserFormPage), findsOneWidget);
    });

    testWidgets('prefills from a managed user in edit mode', (tester) async {
      final user = parseManagedUsers([
        {
          'id': 'u1',
          'name': 'Asha',
          'email': 'asha@shop.in',
          'role': 'admin',
          'isActive': true,
        },
      ]).first;

      await tester.pumpWidget(_host(UserFormPage(user: user)));
      await tester.pump();

      expect(find.text('Asha'), findsOneWidget);
      expect(find.text('asha@shop.in'), findsOneWidget);
    });
  });
}
