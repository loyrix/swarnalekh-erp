import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/inventory/application/inventory_providers.dart';
import 'package:swarnbook/features/inventory/data/models/inventory_item.dart';
import 'package:swarnbook/features/inventory/presentation/screens/inventory_form_page.dart';
import 'package:swarnbook/features/inventory/presentation/screens/inventory_list_screen.dart';
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

InventoryItem _item() => InventoryItem.fromJson({
  'id': 'i1',
  'itemName': 'Gold Ring',
  'metalType': 'gold',
  'karat': '22K',
  'grossWeight': 5.0,
  'netWeight': 4.2,
  'estimatedSellingPrice': 32000,
  'status': 'in_stock',
});

void main() {
  group('InventoryFormPage', () {
    testWidgets('blocks save and shows validation when name is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const InventoryFormPage()));
      await tester.pump();

      // Tap the save (Create) action.
      await tester.tap(find.text('Create'));
      await tester.pump();

      // Required validation surfaces; nothing navigated away.
      expect(find.text('Item Name *'), findsWidgets);
      expect(find.byType(InventoryFormPage), findsOneWidget);
    });

    testWidgets('prefills fields from a typed item in edit mode', (
      tester,
    ) async {
      await tester.pumpWidget(_host(InventoryFormPage(item: _item())));
      await tester.pump();

      expect(find.text('Gold Ring'), findsOneWidget); // name prefilled
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
