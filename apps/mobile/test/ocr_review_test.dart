import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/categories/application/categories_providers.dart';
import 'package:swarnbook/features/categories/data/models/shop_category.dart';
import 'package:swarnbook/features/inventory/presentation/screens/ocr_review_page.dart';
import 'package:swarnbook/l10n/app_localizations.dart';

final _categories = [
  ShopCategory.fromJson(const {
    'id': 'cat-ring',
    'name': 'Ring',
    'prefix': 'RG',
    'active': true,
  }),
  ShopCategory.fromJson(const {
    'id': 'cat-anklet',
    'name': 'Anklet (Payal)',
    'prefix': 'AK',
    'active': true,
  }),
];

Widget _host(Widget home) => ProviderScope(
  overrides: [categoriesProvider.overrideWith((ref) async => _categories)],
  child: MaterialApp(
    theme: buildLightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  group('OcrReviewPage', () {
    testWidgets('shows stone weight and derives net from gross minus stone', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          OcrReviewPage(
            rows: const [
              {
                'itemName': 'Gold Ring',
                'huid': 'HUID123456',
                'metalType': 'gold',
                'karat': '22K',
                'grossWeight': 10.0,
                'netWeight': 8.0,
                'stoneWeight': 2.0,
                'category': 'Ring',
                'warnings': [],
              },
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(); // categories future resolves

      expect(find.text('2.0'), findsOneWidget); // stone weight visible
      expect(find.text('8'), findsOneWidget); // derived net (gross − stone)
    });

    testWidgets('pre-selects the category detected from the scan', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          OcrReviewPage(
            rows: const [
              {
                'itemName': 'Payal Pair',
                'metalType': 'silver',
                'grossWeight': 12.0,
                'netWeight': 12.0,
                'category': 'Anklet', // matches "Anklet (Payal)"
                'warnings': [],
              },
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Anklet (Payal) (AK)'), findsOneWidget);
    });

    testWidgets('requires a category before importing when none detected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          OcrReviewPage(
            rows: const [
              {
                'itemName': 'Mystery Item',
                'metalType': 'gold',
                'grossWeight': 5.0,
                'netWeight': 5.0,
                'warnings': [],
              },
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Import Items'));
      await tester.pump();

      expect(find.text('Select a category'), findsOneWidget);
      expect(find.byType(OcrReviewPage), findsOneWidget);
    });

    testWidgets('has no quantity or hallmark fields', (tester) async {
      await tester.pumpWidget(
        _host(
          OcrReviewPage(
            rows: const [
              {
                'itemName': 'Gold Ring',
                'metalType': 'gold',
                'grossWeight': 5.0,
                'netWeight': 5.0,
                'warnings': [],
              },
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Quantity'), findsNothing);
      expect(find.textContaining('Hallmark'), findsNothing);
    });
  });
}
