import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/dashboard/application/dashboard_providers.dart';
import 'package:swarnbook/features/dashboard/data/models/dashboard_data.dart';
import 'package:swarnbook/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:swarnbook/l10n/app_localizations.dart';

DashboardData _fixture({
  String role = 'owner',
  List<CategoryStockAlert> stockAlerts = const [],
}) => DashboardData(
  userName: 'Asha',
  role: role,
  shopName: 'Kundan Jewellers',
  stats: DashboardStats(
    categoryStockAlerts: stockAlerts,
    totalGoldStock: 21,
    totalSilverStock: 150,
    totalInventoryValue: 139250,
    monthlyRevenue: 40000,
    pendingMortgageInterest: 0,
    activeLoans: 1,
    todaysSales: 15000,
    totalBillsGenerated: 12,
    soldProductsThisMonth: 5,
    salesTrend: [
      SalesTrendPoint(date: '2026-06-25', total: 0),
      SalesTrendPoint(date: '2026-06-26', total: 1000),
      SalesTrendPoint(date: '2026-06-27', total: 0),
      SalesTrendPoint(date: '2026-06-28', total: 5000),
      SalesTrendPoint(date: '2026-06-29', total: 0),
      SalesTrendPoint(date: '2026-06-30', total: 2000),
      SalesTrendPoint(date: '2026-07-01', total: 15000),
    ],
  ),
);

Widget _host(List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    theme: buildLightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(body: DashboardScreen()),
  ),
);

void main() {
  group('DashboardStats parsing', () {
    test('parses bootstrap payload with typed fields and sales trend', () {
      final data = DashboardData.fromBootstrap({
        'stats': {
          'totalGoldStock': '21.000',
          'totalSilverStock': 150,
          'monthlyRevenue': '40000',
          'activeLoans': 1,
          'totalBillsGenerated': 12,
          'soldProductsThisMonth': 5,
          'salesTrend': [
            {'date': '2026-07-01', 'total': '15000'},
            {'date': '2026-06-30', 'total': 2000},
          ],
        },
        'user': {'name': 'Asha', 'role': 'owner'},
        'tenant': {'shopName': 'Kundan Jewellers'},
      });

      expect(data.userName, 'Asha');
      expect(data.role, 'owner');
      expect(data.shopName, 'Kundan Jewellers');
      expect(data.stats.totalGoldStock, 21);
      expect(data.stats.monthlyRevenue, 40000);
      expect(data.stats.salesTrend, hasLength(2));
      expect(data.stats.salesTrend.first.total, 15000);
      expect(data.stats.salesTrend.first.parsedDate, DateTime(2026, 7, 1));
    });

    test('defaults missing fields to zero/empty safely', () {
      final data = DashboardData.fromBootstrap(const {});
      expect(data.userName, '');
      expect(data.stats.totalGoldStock, 0);
      expect(data.stats.activeLoans, 0);
      expect(data.stats.salesTrend, isEmpty);
    });
  });

  group('Stock alerts', () {
    test('parses categoryStockAlerts from the stats payload', () {
      final stats = DashboardStats.fromJson(const {
        'categoryStockAlerts': [
          {
            'id': 'c1',
            'name': 'Ring',
            'prefix': 'RG',
            'inStockCount': 0,
            'minStockThreshold': 2,
            'severity': 'out',
          },
        ],
      });
      final alert = stats.categoryStockAlerts.single;
      expect(alert.name, 'Ring');
      expect(alert.prefix, 'RG');
      expect(alert.isOut, isTrue);
      expect(alert.minStockThreshold, 2);
    });

    testWidgets('shows the alert card and opens the category breakdown', (
      tester,
    ) async {
      final data = _fixture(
        stockAlerts: const [
          CategoryStockAlert(
            id: 'c1',
            name: 'Ring',
            prefix: 'RG',
            inStockCount: 0,
            minStockThreshold: 2,
            isOut: true,
          ),
          CategoryStockAlert(
            id: 'c2',
            name: 'Chain',
            prefix: 'CN',
            inStockCount: 1,
            minStockThreshold: 3,
            isOut: false,
          ),
        ],
      );

      await tester.pumpWidget(
        _host([dashboardProvider.overrideWith((ref) async => data)]),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('2 categories need restocking'), findsOneWidget);

      await tester.tap(find.text('2 categories need restocking'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Ring (RG)'), findsOneWidget);
      expect(find.text('Chain (CN)'), findsOneWidget);
      expect(find.text('In stock: 1 · Min: 3'), findsOneWidget);
    });

    testWidgets('hides the alert card when nothing needs restocking', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host([dashboardProvider.overrideWith((ref) async => _fixture())]),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.textContaining('restocking'), findsNothing);
    });
  });

  group('DashboardScreen states', () {
    testWidgets('shows error + retry on failure', (tester) async {
      await tester.pumpWidget(
        _host([
          dashboardProvider.overrideWith(
            (ref) => Future<DashboardData>.error(Exception('boom')),
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders stats and greeting for loaded data', (tester) async {
      await tester.pumpWidget(
        _host([dashboardProvider.overrideWith((ref) async => _fixture())]),
      );
      await tester.pumpAndSettle();

      // Greeting includes the user name.
      expect(find.textContaining('Asha'), findsWidgets);
      // A representative stat value is rendered.
      expect(find.text('₹40.0K'), findsOneWidget); // monthly revenue
    });

    testWidgets('owner sees the admin-only Add Stock quick action', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host([
          dashboardProvider.overrideWith(
            (ref) async => _fixture(role: 'owner'),
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add_box_rounded), findsOneWidget);
    });

    testWidgets('staff does not see the admin-only Add Stock quick action', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host([
          dashboardProvider.overrideWith(
            (ref) async => _fixture(role: 'staff'),
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add_box_rounded), findsNothing);
    });

    testWidgets('loading shows shimmer, not data', (tester) async {
      final never = Completer<DashboardData>();
      await tester.pumpWidget(
        _host([dashboardProvider.overrideWith((ref) => never.future)]),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('₹40.0K'), findsNothing);
      addTearDown(() => never.complete(_fixture()));
    });
  });
}
