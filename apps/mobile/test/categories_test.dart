import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/categories/data/models/shop_category.dart';
import 'package:swarnbook/features/categories/presentation/screens/category_form_page.dart';
import 'package:swarnbook/l10n/app_localizations.dart';

Widget _host(Widget home) => MaterialApp(
  theme: buildLightTheme(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  group('ShopCategory model', () {
    test('parses a full payload', () {
      final category = ShopCategory.fromJson({
        'id': 'cat-1',
        'name': 'Ring',
        'prefix': 'RG',
        'minStockThreshold': 2,
        'active': true,
        'inStockCount': 5,
        'itemCount': 9,
      });

      expect(category.name, 'Ring');
      expect(category.prefix, 'RG');
      expect(category.minStockThreshold, 2);
      expect(category.active, isTrue);
      expect(category.inStockCount, 5);
      expect(category.itemCount, 9);
    });

    test('treats blank prefix as null and defaults missing counts to 0', () {
      final category = ShopCategory.fromJson({
        'id': 'cat-2',
        'name': 'Custom',
        'prefix': ' ',
      });

      expect(category.prefix, isNull);
      expect(category.minStockThreshold, 0);
      expect(category.inStockCount, 0);
      expect(category.active, isTrue);
    });
  });

  group('CategoryFormPage', () {
    testWidgets('blocks save when the name is empty', (tester) async {
      await tester.pumpWidget(_host(const CategoryFormPage()));
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Enter a category name'), findsOneWidget);
      expect(find.byType(CategoryFormPage), findsOneWidget);
    });

    testWidgets('rejects a one-letter prefix', (tester) async {
      await tester.pumpWidget(_host(const CategoryFormPage()));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).at(0), 'Ring');
      await tester.enterText(find.byType(TextFormField).at(1), 'R');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Prefix needs at least 2 letters'), findsOneWidget);
    });

    testWidgets('prefills fields in edit mode and shows the active switch', (
      tester,
    ) async {
      final category = ShopCategory.fromJson({
        'id': 'cat-1',
        'name': 'Chain',
        'prefix': 'CN',
        'minStockThreshold': 3,
        'active': true,
        'inStockCount': 1,
        'itemCount': 4,
      });

      await tester.pumpWidget(_host(CategoryFormPage(category: category)));
      await tester.pump();

      expect(find.text('Chain'), findsOneWidget);
      expect(find.text('CN'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });
  });
}
