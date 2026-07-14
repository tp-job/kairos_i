import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

/// Turns DesignTokens into a Flutter ThemeData. Keep the mapping
/// mechanical — any actual design decision belongs in design_tokens.dart
/// (or upstream in design-v1.md), not here.
class AppTheme {
  AppTheme._();

  // Re-exported so feature widgets can keep writing `AppTheme.xxx`
  // instead of reaching into DesignTokens directly.
  static const Color background = DesignTokens.background;
  static const Color danger = DesignTokens.error;
  static Color textMuted = DesignTokens.glassTextSecondary;
  static const Color textPrimary = DesignTokens.glassTextPrimary;
  static Color surface = DesignTokens.glassFillLow;

  /// Brand identity (Aurora): violet primary + coral accent, and the
  /// signature gradient for hero surfaces.
  static const Color brand = DesignTokens.brand;
  static const Color accent = DesignTokens.accent;
  static const Gradient brandGradient = DesignTokens.brandGradient;

  static const double cardRadius = DesignTokens.radiusXl;
  static const double gridGap = DesignTokens.spacingUnit * 1.5; // 12px

  /// The standard white "soft card" surface used across the dashboard
  /// (task rows, placeholders, skeletons): white fill, rounded corners,
  /// one quiet shadow. Kept here so the look is defined in one place.
  static BoxDecoration softCard({double radius = 18}) {
    return BoxDecoration(
      color: DesignTokens.cardWhite,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(color: DesignTokens.cardShadow, blurRadius: 16),
      ],
    );
  }

  static TextStyle _textStyle({
    required double fontSize,
    required FontWeight weight,
    required double height,
    double letterSpacing = 0,
    Color color = DesignTokens.glassTextPrimary,
  }) {
    return GoogleFonts.ibmPlexSansThai(
      fontSize: fontSize,
      fontWeight: weight,
      height: height / fontSize, // design tokens give line-height in px
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static ThemeData get light {
    final textTheme = TextTheme(
      // display-lg-mobile — this app is mobile/desktop-window sized,
      // so we use the mobile scale as the default "display" style.
      displayLarge: _textStyle(
        fontSize: 40,
        weight: FontWeight.w600,
        height: 48,
        letterSpacing: -0.02 * 40,
      ),
      headlineSmall: _textStyle(
        fontSize: 24, // headline-md
        weight: FontWeight.w500,
        height: 32,
      ),
      titleMedium: _textStyle(
        fontSize: 18, // body-lg, used for card titles
        weight: FontWeight.w500,
        height: 28,
      ),
      bodyLarge: _textStyle(fontSize: 18, weight: FontWeight.w400, height: 28),
      bodyMedium: _textStyle(fontSize: 16, weight: FontWeight.w400, height: 24),
      bodySmall: _textStyle(
        fontSize: 12, // label-sm
        weight: FontWeight.w600,
        height: 16,
        letterSpacing: 0.05 * 12,
        color: DesignTokens.glassTextSecondary,
      ),
      labelMedium: _textStyle(
        fontSize: 14,
        weight: FontWeight.w500,
        height: 20,
        letterSpacing: 0.01 * 14,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      // Transparent so the app background (wrapped around the app in
      // main.dart) shows through every screen's Scaffold.
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.light(
        primary: DesignTokens.brand,
        onPrimary: DesignTokens.onBrand,
        secondary: DesignTokens.accent,
        onSecondary: DesignTokens.onBrand,
        tertiary: DesignTokens.brand,
        error: DesignTokens.error,
        onError: DesignTokens.onError,
        surface: DesignTokens.background,
        onSurface: DesignTokens.textStrong,
      ),
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: DesignTokens.textMuted),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: DesignTokens.glassTextSecondary),
        border: InputBorder.none,
      ),
    );
  }
}
