import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/customers/application/customers_providers.dart';
import 'package:swarnbook/features/customers/data/models/customer.dart';
import 'package:swarnbook/features/customers/presentation/screens/customer_form_page.dart';
import 'package:swarnbook/features/customers/presentation/screens/customer_list_screen.dart';
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

Customer _c(String name, {String? phone}) => Customer.fromJson({
  'id': name,
  'name': name,
  'phone': phone,
  'totalPurchases': 150000,
  'totalVisits': 4,
});

void main() {
  group('Customer.fromJson', () {
    test('parses typed fields with numeric coercion', () {
      final c = Customer.fromJson({
        'id': 'c1',
        'name': 'Asha',
        'phone': '99999',
        'totalPurchases': '250000',
        'totalVisits': '6',
      });
      expect(c.id, 'c1');
      expect(c.name, 'Asha');
      expect(c.totalPurchases, 250000);
      expect(c.totalVisits, 6);
    });

    test('matches searches name and phone case-insensitively', () {
      final c = _c('Ramesh', phone: '9812345678');
      expect(c.matches('ram'), isTrue);
      expect(c.matches('9812'), isTrue);
      expect(c.matches('zzz'), isFalse);
    });
  });

  group('CustomerListScreen', () {
    testWidgets('renders customer rows', (tester) async {
      await tester.pumpWidget(
        _host(
          const Scaffold(body: CustomerListScreen()),
          overrides: [
            customersProvider.overrideWith(
              (ref) async => [_c('Asha'), _c('Ravi')],
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Asha'), findsOneWidget);
      expect(find.text('Ravi'), findsOneWidget);
    });

    testWidgets('shows empty state when there are no customers', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Scaffold(body: CustomerListScreen()),
          overrides: [customersProvider.overrideWith((ref) async => [])],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('No customers yet'), findsOneWidget);
    });
  });

  group('CustomerFormPage', () {
    testWidgets('blocks save and validates required name', (tester) async {
      await tester.pumpWidget(_host(const CustomerFormPage()));
      await tester.pump();

      await tester.tap(find.text('Create'));
      await tester.pump();

      expect(find.byType(CustomerFormPage), findsOneWidget);
    });

    testWidgets('prefills fields in edit mode', (tester) async {
      await tester.pumpWidget(_host(CustomerFormPage(customer: _c('Asha'))));
      await tester.pump();
      expect(find.text('Asha'), findsOneWidget);
    });
  });
}
