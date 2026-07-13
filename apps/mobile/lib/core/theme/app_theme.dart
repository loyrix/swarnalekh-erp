import 'package:flutter/material.dart';

/// SwarnaLekh Design System — Onyx · Champagne
/// (docs/design-concepts/06-onyx-champagne.html, chosen 2026-07-13)
///
/// Sharp monochrome base + one restrained champagne-gold accent; status &
/// metal colours reserved for real meaning, never decoration. Platform sans
/// (no bundled fonts), semibold headings, tabular numerals for figures.
///
/// Usage: AppColors.of(context).background, etc.

class AppColorTokens {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color primaryMuted;
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color surfaceCard;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnPrimary;
  final Color border;
  final Color borderLight;
  final Color divider;
  final Color glassBorder;
  final LinearGradient cardGradient;
  final LinearGradient surfaceGradient;

  const AppColorTokens({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.primaryMuted,
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.surfaceCard,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnPrimary,
    required this.border,
    required this.borderLight,
    required this.divider,
    required this.glassBorder,
    required this.cardGradient,
    required this.surfaceGradient,
  });
}

/// Static colors that DON'T change with theme
class AppColors {
  AppColors._();

  // Primary — Champagne gold. Static tokens use the dark-mode accent
  // (#C6A25E); light mode maps colorScheme.primary to [primaryDark]
  // (#9C7C3E), the concept's light accent.
  static const Color primary = Color(0xFFC6A25E);
  static const Color primaryLight = Color(0xFFDCBE86);
  static const Color primaryDark = Color(0xFF9C7C3E);
  static const Color primaryMuted = Color(0x33C6A25E);

  // Status colors (used ONLY for real status: in-stock / sold / overdue /
  // error — never as decoration). Single static value tuned to read on both
  // the onyx-dark and paper-light backgrounds.
  static const Color success = Color(0xFF3BAC6E);
  static const Color successMuted = Color(0x333BAC6E);
  static const Color warning = Color(0xFFD5902A);
  static const Color warningMuted = Color(0x33D5902A);
  static const Color error = Color(0xFFD85350);
  static const Color errorMuted = Color(0x33D85350);
  static const Color info = Color(0xFF5687E4);
  static const Color infoMuted = Color(0x335687E4);

  // Metal colors
  static const Color gold = Color(0xFFC6A25E);
  static const Color silver = Color(0xFF959DA8);
  static const Color platinum = Color(0xFF63A39A);
  static const Color rose = Color(0xFFC27F69);

  // Gradients (always the same)
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFC6A25E), Color(0xFF9C7C3E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient goldShimmer = LinearGradient(
    colors: [Color(0xFFDCBE86), Color(0xFFC6A25E), Color(0xFF9C7C3E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========== DARK MODE (onyx) ==========
  static const Color background = Color(0xFF0A0A0C);
  static const Color surface = Color(0xFF151517);
  static const Color surfaceLight = Color(0xFF1C1C1F); // inputs / surface-2
  static const Color surfaceCard = Color(0xFF151517);
  static const Color surfaceElevated = Color(0xFF1C1C1F);
  static const Color textPrimary = Color(0xFFF3F3F5);
  static const Color textSecondary = Color(0xFFA4A4AD);
  static const Color textMuted = Color(0xFF6C6C75);
  static const Color textOnPrimary = Color(0xFF1A1408); // ink on champagne
  static const Color border = Color(0xFF2A2A2F);
  static const Color borderLight = Color(0xFF35353B);
  static const Color divider = Color(0xFF202024);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF17171A), Color(0xFF151517)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF1C1C1F), Color(0xFF151517)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========== LIGHT MODE (paper) ==========
  static const Color backgroundLight = Color(0xFFF4F4F5);
  static const Color surfaceLightMode = Color(0xFFFFFFFF);
  static const Color surfaceLightLight = Color(0xFFFAFAFB); // surface-2
  static const Color surfaceCardLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFFAFAFB);
  static const Color textPrimaryLight = Color(0xFF161619);
  static const Color textSecondaryLight = Color(0xFF57575E);
  static const Color textMutedLight = Color(0xFF9A9AA3);
  static const Color textOnPrimaryLight = Color(0xFF241B06); // ink on gold
  static const Color borderLightMode = Color(0xFFE3E3E7);
  static const Color borderLightLight = Color(0xFFEDEDF0);
  static const Color dividerLight = Color(0xFFEDEDF0);
  static const Color glassBorderLight = Color(0x1A000000);
  static const LinearGradient cardGradientLight = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFCFCFD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient surfaceGradientLight = LinearGradient(
    colors: [Color(0xFFFAFAFB), Color(0xFFF4F4F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Convenience: get adaptive colors given brightness
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      isDark(context) ? background : backgroundLight;
  static Color surf(BuildContext context) =>
      isDark(context) ? surface : surfaceLightMode;
  static Color surfL(BuildContext context) =>
      isDark(context) ? surfaceLight : surfaceLightLight;
  static Color card(BuildContext context) =>
      isDark(context) ? surfaceCard : surfaceCardLight;
  static Color elev(BuildContext context) =>
      isDark(context) ? surfaceElevated : surfaceElevatedLight;
  static Color text1(BuildContext context) =>
      isDark(context) ? textPrimary : textPrimaryLight;
  static Color text2(BuildContext context) =>
      isDark(context) ? textSecondary : textSecondaryLight;
  static Color text3(BuildContext context) =>
      isDark(context) ? textMuted : textMutedLight;
  static Color brd(BuildContext context) =>
      isDark(context) ? border : borderLightMode;
  static Color div(BuildContext context) =>
      isDark(context) ? divider : dividerLight;
  static LinearGradient cardGrad(BuildContext context) =>
      isDark(context) ? cardGradient : cardGradientLight;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Onyx Champagne is deliberately square: concept radii are 8/6/5px.
/// xl/xxl exist for the rare hero/sheet that needs a touch more.
class AppRadius {
  AppRadius._();
  static const double sm = 5;
  static const double md = 6;
  static const double lg = 8;
  static const double xl = 10;
  static const double xxl = 12;
  static const double full = 999;
}

/// Canonical responsive breakpoints. Use these instead of scattering magic
/// widths (768/900/600/…) across screens so the mobile/desktop switch is
/// consistent everywhere.
class AppBreakpoints {
  AppBreakpoints._();

  /// Below this width we treat the layout as a phone (compact).
  static const double compact = 768;

  /// At/above this width we treat the layout as a wide desktop.
  static const double expanded = 1024;
}

/// Density/layout helpers derived from [AppBreakpoints]. Prefer these over
/// ad-hoc `MediaQuery`/`LayoutBuilder` width comparisons.
class AppDensity {
  AppDensity._();

  /// True on phone-sized layouts (width < [AppBreakpoints.compact]).
  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppBreakpoints.compact;

  /// True on wide desktop layouts (width >= [AppBreakpoints.expanded]).
  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppBreakpoints.expanded;

  /// Compact-aware value picker: returns [compact] on phones, else [wide].
  static T pick<T>(
    BuildContext context, {
    required T compact,
    required T wide,
  }) => isCompact(context) ? compact : wide;
}

class AppShadows {
  AppShadows._();

  // Onyx Champagne shadows are near-hairlines: 0 1px 2px, no glow.
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
  static List<BoxShadow> cardLight = [
    BoxShadow(
      color: const Color(0xFF141419).withValues(alpha: 0.06),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
  static List<BoxShadow> elevated = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];
  static List<BoxShadow> elevatedLight = [
    BoxShadow(
      color: const Color(0xFF141419).withValues(alpha: 0.10),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];
  // The one sanctioned gold shadow: the solid primary action (concept
  // .chip.solid — 0 6px 18px accent 35%).
  static List<BoxShadow> goldGlow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.30),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> forCard(BuildContext context) =>
      AppColors.isDark(context) ? card : cardLight;
  static List<BoxShadow> forElevated(BuildContext context) =>
      AppColors.isDark(context) ? elevated : elevatedLight;

  /// A whisper-soft lift for compact list rows / stat cards — premium depth
  /// without extra height. Tuned per theme.
  static List<BoxShadow> softLight = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];
  static List<BoxShadow> softDark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];
  static List<BoxShadow> soft(BuildContext context) =>
      AppColors.isDark(context) ? softDark : softLight;
}

// ====================================
// Theme Builder
// ====================================

/// Tabular figures everywhere: amounts/weights align in columns and stat
/// tiles don't jitter as values change. Harmless for plain text.
const List<FontFeature> _tabularFigures = [FontFeature.tabularFigures()];

/// The concept's family: "Helvetica Neue" (its own fallbacks are the platform
/// grotesques — SF/Roboto/Segoe). iOS/macOS resolve Helvetica Neue natively;
/// Android and Flutter-web fall back to Roboto. Applied via
/// `ThemeData(fontFamily:)` so every style inherits it.
const String kAppFontFamily = 'Helvetica Neue';

/// Type scale transcribed from 06-onyx-champagne.html — NOT just recolored:
/// headings are semibold (w600, never w700) with slightly *positive* tracking
/// (.2–.5px, no tight negative spacing); body is 15px; row titles 13.5 w600;
/// w700 exists only at label-small size (eyebrows/status chips, wide-tracked).
TextTheme _buildTextTheme(Color primary, Color secondary, Color muted) {
  return TextTheme(
    // Hero figure (concept .headline .v — 44px w600 ls .5).
    displayLarge: TextStyle(
      fontSize: 44,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: 0.5,
      height: 1.05,
      fontFeatures: _tabularFigures,
    ),
    displayMedium: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: 0.3,
      fontFeatures: _tabularFigures,
    ),
    // Greeting-level heading (concept .greet h2 — 27px w600 ls .2).
    displaySmall: TextStyle(
      fontSize: 27,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: 0.2,
      fontFeatures: _tabularFigures,
    ),
    // Screen/brand title (concept .brand h1 — 21px w600 ls .3).
    headlineMedium: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: 0.3,
      fontFeatures: _tabularFigures,
    ),
    headlineSmall: TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: 0.2,
      fontFeatures: _tabularFigures,
    ),
    // Card heading (concept .card-h h3 — 17px w600 ls .2).
    titleLarge: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: 0.2,
      fontFeatures: _tabularFigures,
    ),
    // Stat/row figure (concept .lrow .amt .n — 16px w600).
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: primary,
      fontFeatures: _tabularFigures,
    ),
    // List-row title (concept .lrow .ttl — 13.5px w600).
    titleSmall: TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      color: primary,
      fontFeatures: _tabularFigures,
    ),
    // Body (concept base — 15px, line-height 1.5).
    bodyLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: primary,
      height: 1.5,
      fontFeatures: _tabularFigures,
    ),
    bodyMedium: TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      color: secondary,
      height: 1.45,
      fontFeatures: _tabularFigures,
    ),
    // Meta line (concept .lrow .meta / .sub — 11.5–12px).
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: muted,
      fontFeatures: _tabularFigures,
    ),
    // Buttons/chips (concept .chip — 13px w600).
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: 0.2,
      fontFeatures: _tabularFigures,
    ),
    // Pill selects / small controls (concept .pill-select — 12px w600).
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: secondary,
      letterSpacing: 0.2,
      fontFeatures: _tabularFigures,
    ),
    // Eyebrows / status chips (concept — 11px w700, wide tracking; pair with
    // uppercase text at the call site).
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: muted,
      letterSpacing: 1.0,
      fontFeatures: _tabularFigures,
    ),
  );
}

ThemeData buildDarkTheme() {
  final textTheme = _buildTextTheme(
    AppColors.textPrimary,
    AppColors.textSecondary,
    AppColors.textMuted,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: kAppFontFamily,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      secondary: AppColors.primaryLight,
      // Soft champagne-tinted tile for filledTonal icon buttons
      // (accent at ~14% over the onyx surface).
      secondaryContainer: Color(0xFF2E2921),
      onSecondaryContainer: AppColors.primary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      outline: AppColors.border,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.headlineMedium,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedColor: AppColors.primaryMuted,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      labelStyle: textTheme.labelMedium,
    ),
  );
}

ThemeData buildLightTheme() {
  final textTheme = _buildTextTheme(
    AppColors.textPrimaryLight,
    AppColors.textSecondaryLight,
    AppColors.textMutedLight,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: kAppFontFamily,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryDark,
      onPrimary: AppColors.textOnPrimaryLight,
      secondary: AppColors.primary,
      // Soft champagne-tinted tile for filledTonal icon buttons
      // (accent at ~10% over white).
      secondaryContainer: Color(0xFFF5F2EC),
      onSecondaryContainer: Color(0xFF6E5622), // accent ink
      surface: AppColors.surfaceLightMode,
      onSurface: AppColors.textPrimaryLight,
      error: AppColors.error,
      outline: AppColors.borderLightMode,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceLightMode,
      foregroundColor: AppColors.textPrimaryLight,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.headlineMedium,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceCardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.borderLightMode, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      // White fields on the deeper cream background read cleanly and separate
      // from both the page and white cards (via the defined border).
      fillColor: AppColors.surfaceLightMode,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.borderLightMode),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.borderLightMode),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.5),
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.textMutedLight,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textOnPrimaryLight,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        side: const BorderSide(color: AppColors.primaryDark),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.dividerLight,
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(
      color: AppColors.textSecondaryLight,
      size: 22,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceLightLight,
      selectedColor: AppColors.primaryMuted,
      side: const BorderSide(color: AppColors.borderLightMode),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      labelStyle: textTheme.labelMedium,
    ),
  );
}

/// For backward compat — defaults to dark
ThemeData buildAppTheme() => buildDarkTheme();

// ====================================
// Theme Notifier (simple ValueNotifier)
// ====================================

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark);

  bool get isDark => value == ThemeMode.dark;

  void toggle() {
    value = isDark ? ThemeMode.light : ThemeMode.dark;
  }
}

/// Global instance (will move to Riverpod later)
final themeNotifier = ThemeNotifier();
