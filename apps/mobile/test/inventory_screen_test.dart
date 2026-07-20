import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/categories/application/categories_providers.dart';
import 'package:swarnbook/features/categories/data/models/shop_category.dart';
import 'package:swarnbook/features/inventory/application/inventory_providers.dart';
import 'package:swarnbook/features/inventory/data/models/inventory_item.dart';
import 'package:swarnbook/features/inventory/presentation/screens/inventory_form_page.dart';
import 'package:swarnbook/features/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:swarnbook/l10n/app_localizations.dart';

final _categories = [
  ShopCategory.fromJson(const {
    'id': 'cat-ring',
    'name': 'Ring',
    'prefix': 'RG',
    'minStockThreshold': 0,
    'active': true,
  }),
  ShopCategory.fromJson(const {
    'id': 'cat-chain',
    'name': 'Chain',
    'prefix': 'CN',
    'minStockThreshold': 0,
    'active': true,
  }),
];

Widget _host(Widget home, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => _categories),
        ...overrides,
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

InventoryItem _item() => InventoryItem.fromJson({
  'id': 'i1',
  'itemName': 'Gold Ring',
  'tagNumber': 'RG-07',
  'categoryId': 'cat-ring',
  'metalType': 'gold',
  'karat': '22K',
  'grossWeight': 5.0,
  'netWeight': 4.2,
  'estimatedSellingPrice': 32000,
  'status': 'in_stock',
});

void main() {
  group('InventoryFormPage', () {
    testWidgets('asks for optional details instead of a product name', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const InventoryFormPage()));
      await tester.pump();

      // The duplicate Product Name input is gone; the item name derives from
      // the category with an optional details suffix.
      expect(find.text('Item Name *'), findsNothing);
      expect(find.text('Details (optional)'), findsOneWidget);
    });

    testWidgets('offers an editable optional Tag Number when adding', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const InventoryFormPage()));
      await tester.pump();

      final tag = find.widgetWithText(TextFormField, 'Tag Number');
      expect(tag, findsOneWidget);
      final field = tester.widget<TextFormField>(tag);
      expect(field.enabled, isNot(false)); // editable, unlike the edit view
    });

    test('composeItemName derives the name from category + details', () {
      expect(InventoryFormPage.composeItemName('Chain', ''), 'Chain');
      expect(
        InventoryFormPage.composeItemName('Chain', 'Hollow Rope'),
        'Chain (Hollow Rope)',
      );
    });

    testWidgets('prefills details, tag, and category in edit mode', (
      tester,
    ) async {
      await tester.pumpWidget(_host(InventoryFormPage(item: _item())));
      await tester.pump();

      // Legacy name that doesn't match the "Category (X)" pattern is shown
      // verbatim in the details field so nothing is hidden.
      expect(find.text('Gold Ring'), findsOneWidget);
      expect(find.text('RG-07'), findsOneWidget); // read-only tag shown
      expect(find.text('Ring (RG)'), findsOneWidget); // category preselected
    });

    testWidgets(
      'parses "Category (details)" names back into the details field',
      (tester) async {
        final item = InventoryItem.fromJson({
          'id': 'i2',
          'itemName': 'Ring (Solitaire)',
          'categoryId': 'cat-ring',
          'categoryName': 'Ring',
          'metalType': 'gold',
          'karat': '22K',
          'grossWeight': 5.0,
          'netWeight': 4.2,
          'status': 'in_stock',
        });
        await tester.pumpWidget(_host(InventoryFormPage(item: item)));
        await tester.pump();

        expect(find.text('Solitaire'), findsOneWidget);
        expect(find.text('Ring (Solitaire)'), findsNothing);
      },
    );

    testWidgets('requires a karat and a category before saving', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const InventoryFormPage()));
      await tester.pump();

      await tester.tap(find.text('Create'));
      await tester.pump();

      // Karat is mandatory so every item can be priced from the daily rate.
      expect(find.text('Karat / purity is required'), findsOneWidget);
      // Category is mandatory: it drives the auto-generated tag number.
      expect(find.text('Select a category'), findsOneWidget);
      expect(find.byType(InventoryFormPage), findsOneWidget);
    });

    testWidgets('auto-calculates net weight as gross minus stone', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const InventoryFormPage()));
      await tester.pump();

      final gross = find.widgetWithText(TextFormField, 'Gross Weight *');
      final stone = find.widgetWithText(TextFormField, 'Stone Weight (g)');
      await tester.enterText(gross, '10.5');
      await tester.enterText(stone, '2.25');
      await tester.pump();

      expect(find.text('8.25'), findsOneWidget); // derived net weight
    });

    testWidgets('has no design number, price, or branch fields', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const InventoryFormPage()));
      await tester.pump();

      expect(find.text('Design Number'), findsNothing);
      expect(find.textContaining('Selling Price'), findsNothing);
      expect(find.textContaining('Purchase'), findsNothing);
      expect(find.textContaining('Making'), findsNothing);
      expect(find.textContaining('Branch'), findsNothing);
      expect(find.textContaining('Milligrams'), findsNothing);
      expect(find.textContaining('Image URL'), findsNothing);
    });
  });

  group('InventoryListScreen', () {
    testWidgets('renders inventory rows from the overview provider', (
      tester,
    ) async {
      final overview = InventoryOverview(
        items: [
          _item(),
          InventoryItem.fromJson({'id': 'i2', 'itemName': 'Silver Coin'}),
        ],
        stats: InventoryStats.fromJson(const {'totalProducts': 2}),
      );

      await tester.pumpWidget(
        _host(
          const Scaffold(body: InventoryListScreen()),
          overrides: [
            inventoryOverviewProvider.overrideWith(
              (ref, query) async => overview,
            ),
          ],
        ),
      );
      // Resolve the overview future (avoid pumpAndSettle: shimmer repeats).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Gold Ring'), findsOneWidget);
      expect(find.text('Silver Coin'), findsOneWidget);
    });

    testWidgets('taps the gold tile through to the karat breakdown sheet', (
      tester,
    ) async {
      final overview = InventoryOverview(
        items: [_item()],
        stats: InventoryStats.fromJson(const {
          'totalProducts': 1,
          'totalGoldWeight': 10.5,
          'metalBreakdown': [
            {
              'metalType': 'gold',
              'count': 1,
              'quantity': 1,
              'totalWeight': 10.5,
            },
          ],
          'karatBreakdown': [
            {
              'metalType': 'gold',
              'karats': [
                {'karat': '22K', 'count': 1, 'totalWeight': 10.5},
              ],
            },
          ],
        }),
      );

      await tester.pumpWidget(
        _host(
          const Scaffold(body: InventoryListScreen()),
          overrides: [
            inventoryOverviewProvider.overrideWith(
              (ref, query) async => overview,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Total Gold Weight'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Gold by Karat'), findsOneWidget);
      expect(find.text('22K'), findsOneWidget);
    });

    testWidgets('shows quick gold/silver filter chips on the stock tab', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Scaffold(body: InventoryListScreen()),
          overrides: [
            inventoryOverviewProvider.overrideWith(
              (ref, query) async =>
                  const InventoryOverview(items: [], stats: null),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Gold'), findsWidgets);
      expect(find.text('Silver'), findsWidgets);
    });

    testWidgets('shows the inventory empty state when there are no items', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Scaffold(body: InventoryListScreen()),
          overrides: [
            inventoryOverviewProvider.overrideWith(
              (ref, query) async =>
                  const InventoryOverview(items: [], stats: null),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Your inventory is empty'), findsOneWidget);
    });
  });
}
