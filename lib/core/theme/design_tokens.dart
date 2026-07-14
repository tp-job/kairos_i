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

  // --- "Studio" light theme (project-management reference) ---------------
  // Charcoal accents on a soft off-white base. `ink` remains the neutral
  // dark used for text and any surface meant to read as ink rather than
  // brand. Brand-colored surfaces use the Aurora tokens below.
  static const ink = Color(0xFF2A2A2A);
  static const onInk = Color(0xFFFFFFFF);

  // --- "Aurora" brand theme: violet → coral -------------------------------
  // The app's identity colors. `brand` is the primary (solid fills, active
  // states, FAB, buttons); `accent` is the warm pop and the far stop of the
  // signature gradient used on hero surfaces (header, primary/featured
  // cards). Both are surfaced through AppTheme's ColorScheme too.
  static const brandViolet = Color(0xFF6C5CE7);
  static const brandCoral = Color(0xFFFF5F5E);
  static const brand = brandViolet;
  static const onBrand = Color(0xFFFFFFFF);
  static const accent = brandCoral;

  /// Signature two-stop gradient (violet → coral) for hero surfaces.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandViolet, brandCoral],
  );

  /// App canvas (the phone screen) and the slightly cooler page behind it.
  static const background = Color(0xFFFAFAFA);
  static const pageBackdrop = Color(0xFFE8ECF1); // FAB ring / device frame
  static const cardWhite = Color(0xFFFFFFFF);
  static const secondaryCard = Color(0xFFEEF2FF); // pale indigo tile

  /// Text ramp: strong (headings), muted (body), faint (meta/inactive).
  static const textStrong = Color(0xFF1F2933);
  static const textMuted = Color(0xFF6B7280);
  static const textFaint = Color(0xFF9CA3AF);

  static const hairline = Color(0xFFE5E7EB);
  static final Color cardShadow = Colors.black.withValues(alpha: 0.06);

  // --- Back-compat aliases: older glass widgets still read these names.
  // Repointed to the light palette so nothing renders invisibly. ---
  static const glassTextPrimary = textStrong;
  static const glassTextSecondary = textMuted;
  static const glassBorder = hairline;
  static const glassBorderFocused = ink;
  static const glassFillLow = cardWhite;
  static const glassFillMid = secondaryCard;
  static const glassFillHigh = Color(0xFFF1F5F9);
  static final Color glassShadowTint = cardShadow;

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
