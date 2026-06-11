import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swarnbook/core/localization/locale_notifier.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/core/router/app_router.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/keyboard_aware.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  final supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Missing Supabase config. Create apps/mobile/.env and build with --dart-define-from-file=.env.',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const ProviderScope(child: SwarnaLekhApp()));
}

class SwarnaLekhApp extends ConsumerWidget {
  const SwarnaLekhApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<Locale?>(
          valueListenable: localeNotifier,
          builder: (context, locale, _) {
            return MaterialApp.router(
              title: 'SwarnaLekh — Jewellery Management',
              debugShowCheckedModeBanner: false,
              theme: buildLightTheme(),
              darkTheme: buildDarkTheme(),
              themeMode: themeMode,
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
              builder: (context, child) {
                return ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                  ),
                  child: KeyboardDismissRegion(
                    child: ColoredBox(
                      color: AppColors.bg(context),
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
