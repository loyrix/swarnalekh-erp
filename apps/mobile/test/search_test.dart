import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/search/application/search_providers.dart';
import 'package:swarnbook/features/search/data/models/search_results.dart';
import 'package:swarnbook/features/search/presentation/screens/search_screen.dart';
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

final _results = SearchResults.fromJson({
  'query': 'ring',
  'customers': [
    {'id': 'c1', 'name': 'Ring Buyer', 'phone': '99999', 'city': 'Pune'},
  ],
  'inventory': [
    {
      'id': 'i1',
      'tagNumber': 'RING-7',
      'itemName': 'Gold Ring',
      'category': 'Rings',
      'metalType': 'gold',
      'status': 'in_stock',
      'sellingPrice': 60000,
    },
  ],
  'invoices': [
    {
      'id': 'inv1',
      'invoiceNumber': 'SLK-2026-0001',
      'customerName': 'Ring Buyer',
      'invoiceDate': '2026-06-10',
      'grandTotal': 60000,
      'balanceDue': 0,
    },
  ],
  'total': 3,
});

void main() {
  group('SearchResults.fromJson', () {
    test('parses grouped hits with numeric coercion and nulls', () {
      final r = SearchResults.fromJson({
        'query': 'a',
        'customers': [
          {'id': 'c1', 'name': 'Asha', 'phone': '', 'city': null},
        ],
        'inventory': [
          {'id': 'i1', 'metalType': 'gold', 'status': 'sold'},
        ],
        'invoices': [],
        'total': 2,
      });
      expect(r.total, 2);
      expect(r.customers.single.name, 'Asha');
      // Empty string coerces to null for optional fields.
      expect(r.customers.single.phone, isNull);
      expect(r.inventory.single.tagNumber, isNull);
      expect(r.inventory.single.sellingPrice, isNull);
      expect(r.invoices, isEmpty);
      expect(r.isEmpty, isFalse);
    });

    test('derives total from group lengths when absent', () {
      final r = SearchResults.fromJson({
        'customers': [
          {'id': 'c1', 'name': 'Asha'},
        ],
        'inventory': [],
        'invoices': [],
      });
      expect(r.total, 1);
    });

    test('empty constant reports isEmpty', () {
      expect(SearchResults.empty.isEmpty, isTrue);
    });
  });

  group('SearchScreen', () {
    testWidgets('shows the start prompt before any query', (tester) async {
      await tester.pumpWidget(_host(const SearchScreen()));
      await tester.pump();
      expect(find.text('Search everything'), findsOneWidget);
    });

    testWidgets('renders grouped results after typing a query', (tester) async {
      await tester.pumpWidget(
        _host(
          const SearchScreen(),
          overrides: [
            searchResultsProvider.overrideWith((ref, query) async => _results),
          ],
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'ring');
      // Wait out the 300ms debounce, then the resolved future.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(find.text('Ring Buyer'), findsWidgets);
      expect(find.text('Gold Ring'), findsOneWidget);
      expect(find.text('SLK-2026-0001'), findsOneWidget);
      // Group headers carry counts.
      expect(find.textContaining('(1)'), findsNWidgets(3));
    });

    testWidgets('shows no-results empty state for an empty payload', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SearchScreen(),
          overrides: [
            searchResultsProvider.overrideWith(
              (ref, query) async => SearchResults.empty,
            ),
          ],
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(find.text('No results found'), findsOneWidget);
    });
  });
}
