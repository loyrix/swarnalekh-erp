import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/presentation/screens/welcome_screen.dart';
import 'package:swarnbook/l10n/app_localizations.dart';

/// Hosts the welcome screen behind a router with stub destinations, so taps can
/// be asserted without pulling in the real login/signup screens (which hit the
/// network on mount).
Widget _host(GoRouter router) => ProviderScope(
  child: MaterialApp.router(
    theme: buildLightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  ),
);

GoRouter _router() => GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('LOGIN STUB'))),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('SIGNUP STUB'))),
    ),
  ],
);

void main() {
  group('WelcomeScreen', () {
    testWidgets('offers both entry paths with their own explanation', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_router()));
      await tester.pumpAndSettle();

      expect(find.text('Register your shop'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
      expect(find.byIcon(Icons.login_rounded), findsOneWidget);
    });

    testWidgets('registering takes the visitor to signup', (tester) async {
      await tester.pumpWidget(_host(_router()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Register your shop'));
      await tester.pumpAndSettle();

      expect(find.text('SIGNUP STUB'), findsOneWidget);
    });

    testWidgets('signing in takes the visitor to login', (tester) async {
      await tester.pumpWidget(_host(_router()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('LOGIN STUB'), findsOneWidget);
    });

    testWidgets('tells staff they are enrolled by their shop owner', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_router()));
      await tester.pumpAndSettle();

      // Staff self-registering would create an orphan tenant, so the screen has
      // to say this before they pick the wrong path.
      expect(
        find.textContaining("Staff members don't register"),
        findsOneWidget,
      );
    });

    testWidgets('renders in dark theme without overflowing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: buildDarkTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _router(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('fits a small phone screen', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_host(_router()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
