import 'package:flutter/material.dart';

/// Raw values transcribed 1:1 from .agent/design-system/markdown/design-v1.md
/// ("Celestial Glass"). Nothing in here is decided by app code — if the
/// design system changes, this is the only file that should need edits.
/// AppTheme (app_theme.dart) turns these into a Flutter ThemeData; the
/// glass effect itself lives in core/widgets/glass_container.dart.
class DesignTokens {
  DesignTokens._();

  // --- Colors (from the design-v1.md front matter) ---
  static const surface = Color(0xFFF9F9F9);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF1A1C1C);
  static const onSurfaceVariant = Color(0xFF5A413F);
  static const outline = Color(0xFF8D706E);
  static const outlineVariant = Color(0xFFE1BEBC);

  /// Primary — "Solaris Red": critical actions, brand-heavy elements.
  static const primary = Color(0xFFB3272D);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFFF5F5E);

  /// Secondary — "Twilight Purple": depth, shadows, secondary focal points.
  static const secondary = Color(0xFF5644D0);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF6F5FEA);

  /// Tertiary — "Dawn Orange": highlights, warm accents in gradients.
  static const tertiary = Color(0xFF934A27);
  static const tertiaryContainer = Color(0xFFD67F58);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);

  static const background = Color(0xFFF9F9F9);
  static const onBackground = Color(0xFF1A1C1C);

  // --- Glass surface: white text/borders at low opacity, per the
  // "Elevation & Depth" section (10%-40% opacity tiers, 20% borders). ---
  static const glassTextPrimary = Colors.white;
  static final Color glassTextSecondary = Colors.white.withValues(alpha: 0.70);
  static final Color glassBorder = Colors.white.withValues(alpha: 0.20);
  static final Color glassBorderFocused = Colors.white.withValues(alpha: 0.60);
  static final Color glassFillLow = Colors.white.withValues(alpha: 0.10);
  static final Color glassFillMid = Colors.white.withValues(alpha: 0.18);
  static final Color glassFillHigh = Colors.white.withValues(alpha: 0.30);
  static final Color glassShadowTint = secondary.withValues(alpha: 0.10);

  // --- Typography: font family + the named type scale. ---
  static const fontFamilyName = 'IBM Plex Sans Thai';

  // --- Shape ---
  static const radiusSm = 4.0; // 0.25rem
  static const radiusDefault = 8.0; // 0.5rem
  static const radiusMd = 12.0; // 0.75rem
  static const radiusLg = 16.0; // 1rem
  static const radiusXl = 24.0; // 1.5rem — cards / "glass vessels"
  static const radiusFull = 9999.0;

  // --- Spacing (8px base unit) ---
  static const spacingUnit = 8.0;
  static const containerPaddingDesktop = 64.0;
  static const containerPaddingMobile = 24.0;
  static const gutter = 24.0;
  static const cardPadding = 32.0;

  // --- Elevation ---
  static const backdropBlurSigma = 20.0; // matches `blur(20px)`
}
