import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/presentation/screens/login_screen.dart';
import 'package:swarnbook/features/auth/presentation/screens/signup_screen.dart';
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
  group('LoginScreen', () {
    testWidgets('blocks login and validates empty credentials', (tester) async {
      await tester.pumpWidget(_host(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(GoldButton));
      await tester.tap(find.byType(GoldButton));
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });
  });

  group('SignupScreen', () {
    testWidgets('validates shop, owner and email when empty', (tester) async {
      await tester.pumpWidget(_host(const SignupScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(GoldButton));
      await tester.tap(find.byType(GoldButton));
      await tester.pump();

      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.text('Shop name is required'), findsOneWidget);
      expect(find.text('Owner name is required'), findsOneWidget);
      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('flags mismatched passwords', (tester) async {
      await tester.pumpWidget(_host(const SignupScreen()));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      // order: shop, owner, email, password, confirm
      await tester.enterText(fields.at(3), 'password1');
      await tester.enterText(fields.at(4), 'password2');

      await tester.ensureVisible(find.byType(GoldButton));
      await tester.tap(find.byType(GoldButton));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
