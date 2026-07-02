import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/security/application/security_providers.dart';
import 'package:swarnbook/features/security/data/models/activity_log.dart';
import 'package:swarnbook/features/security/presentation/screens/security_screen.dart';
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

ActivityLogPage _page() => ActivityLogPage.fromJson({
  'total': 1,
  'logs': [
    {
      'id': 'a',
      'action': 'update',
      'entityType': 'inventory',
      'user': {'name': 'Asha', 'role': 'owner'},
      'createdAt': '2026-06-10T09:30:00.000Z',
    },
  ],
});

void main() {
  group('SecurityScreen', () {
    testWidgets('renders activity rows from the provider', (tester) async {
      await tester.pumpWidget(
        _host(
          const Scaffold(body: SecurityScreen()),
          overrides: [
            activityLogsProvider.overrideWith((ref, query) async => _page()),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('Asha'), findsOneWidget);
      expect(find.text('UPDATE'), findsOneWidget);
    });

    testWidgets('shows empty state when there are no logs', (tester) async {
      await tester.pumpWidget(
        _host(
          const Scaffold(body: SecurityScreen()),
          overrides: [
            activityLogsProvider.overrideWith(
              (ref, query) async => ActivityLogPage.fromJson(const {}),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('No activity logs found.'), findsOneWidget);
    });
  });
}
