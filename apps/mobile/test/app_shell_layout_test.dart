import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/layouts/app_shell.dart';

void main() {
  testWidgets('mobile shell respects status and home safe areas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
    });

    final flutterErrors = <FlutterErrorDetails>[];
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = flutterErrors.add;

    try {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AppShell(
              currentIndex: 0,
              currentTitle: 'Dashboard',
              loadRole: () async => 'owner',
              signOut: () async {},
              onNavigate: (_) {},
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = previousErrorHandler;
    }

    expect(
      flutterErrors.where(
        (details) => details.exceptionAsString().contains('overflowed'),
      ),
      isEmpty,
    );
    expect(tester.getTopLeft(find.text('Dashboard').first).dy, greaterThan(47));
    expect(
      tester.getBottomLeft(find.text('Dashboard').last).dy,
      lessThan(844 - 34),
    );
  });
}
