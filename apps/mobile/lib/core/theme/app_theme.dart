import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SwarnaLekh Design System
/// Adaptive dark/light theme with gold accents — jewellery aesthetic
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

  // Primary — Rich Gold (always the same)
  static const Color primary = Color(0xFFD4A853);
  static const Color primaryLight = Color(0xFFE8C97A);
  static const Color primaryDark = Color(0xFFB8902E);
  static const Color primaryMuted = Color(0x33D4A853);

  // Accent colors (always the same)
  static const Color success = Color(0xFF34C759);
  static const Color successMuted = Color(0x3334C759);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color warningMuted = Color(0x33FF9F0A);
  static const Color error = Color(0xFFFF453A);
  static const Color errorMuted = Color(0x33FF453A);
  static const Color info = Color(0xFF5E9EFF);
  static const Color infoMuted = Color(0x335E9EFF);

  // Metal colors
  static const Color gold = Color(0xFFD4A853);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color platinum = Color(0xFFE5E4E2);
  static const Color rose = Color(0xFFE8A090);

  // Gradients (always the same)
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4A853), Color(0xFFB8902E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient goldShimmer = LinearGradient(
    colors: [Color(0xFFE8C97A), Color(0xFFD4A853), Color(0xFFB8902E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========== DARK MODE ==========
  static const Color background = Color(0xFF0D0D12);
  static const Color surface = Color(0xFF161621);
  static const Color surfaceLight = Color(0xFF1E1E2D);
  static const Color surfaceCard = Color(0xFF1A1A28);
  static const Color surfaceElevated = Color(0xFF22223A);
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFA1A1B5);
  static const Color textMuted = Color(0xFF6B6B80);
  static const Color textOnPrimary = Color(0xFF1A1A28);
  static const Color border = Color(0xFF2A2A3D);
  static const Color borderLight = Color(0xFF33334D);
  static const Color divider = Color(0xFF1F1F33);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E30), Color(0xFF161625)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF1E1E2D), Color(0xFF161621)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========== LIGHT MODE ==========
  static const Color backgroundLight = Color(0xFFF7F6F3);
  static const Color surfaceLightMode = Color(0xFFFFFFFF);
  static const Color surfaceLightLight = Color(0xFFF0EDE8);
  static const Color surfaceCardLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFF5F2ED);
  static const Color textPrimaryLight = Color(0xFF1A1A28);
  static const Color textSecondaryLight = Color(0xFF6B6B80);
  static const Color textMutedLight = Color(0xFF9E9EB0);
  static const Color textOnPrimaryLight = Color(0xFFFFFFFF);
  static const Color borderLightMode = Color(0xFFE5E2DC);
  static const Color borderLightLight = Color(0xFFEAE7E2);
  static const Color dividerLight = Color(0xFFEDE9E3);
  static const Color glassBorderLight = Color(0x1A000000);
  static const LinearGradient cardGradientLight = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFCFAF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient surfaceGradientLight = LinearGradient(
    colors: [Color(0xFFF5F2ED), Color(0xFFF0EDE8)],
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

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double full = 999;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> cardLight = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> elevated = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  static List<BoxShadow> elevatedLight = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  static List<BoxShadow> goldGlow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> forCard(BuildContext context) =>
      AppColors.isDark(context) ? card : cardLight;
  static List<BoxShadow> forElevated(BuildContext context) =>
      AppColors.isDark(context) ? elevated : elevatedLight;
}

// ====================================
// Theme Builder
// ====================================

TextTheme _buildTextTheme(Color primary, Color secondary, Color muted) {
  return GoogleFonts.interTextTheme().copyWith(
    displayLarge: GoogleFonts.outfit(
      fontSize: 42,
      fontWeight: FontWeight.w700,
      color: primary,
      letterSpacing: -1.4,
    ),
    displayMedium: GoogleFonts.outfit(
      fontSize: 34,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: -0.4,
    ),
    displaySmall: GoogleFonts.outfit(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    headlineMedium: GoogleFonts.outfit(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    headlineSmall: GoogleFonts.outfit(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: secondary,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      color: primary,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: secondary,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: muted,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: 0.4,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: secondary,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: muted,
      letterSpacing: 0.4,
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
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      secondary: AppColors.primaryLight,
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
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryDark,
      onPrimary: AppColors.textOnPrimaryLight,
      secondary: AppColors.primary,
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
      fillColor: AppColors.surfaceLightLight,
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
