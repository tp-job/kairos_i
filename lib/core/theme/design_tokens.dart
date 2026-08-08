/// Non-color design tokens: shape, spacing, typography names, elevation.
///
/// Color lives in exactly two places now — `material_scheme.dart` (the
/// Material Theme Builder export) and `kairos_palette.dart` (the few roles
/// Material has no name for). Widgets read both through `Theme.of(context)`,
/// which is why there is no `Color` in this file: a static color cannot know
/// whether the app is currently light, dark, or high contrast, and every bug
/// this refactor fixed traced back to one that thought it could.
class DesignTokens {
  DesignTokens._();

  // --- Shape ---------------------------------------------------------------
  // The Japandi brief pins the signature corner to 16–24: rounded enough to
  // read as friendly, tight enough that a bento tile still reads as a *box*.
  // Past ~28 a half-width card turns into a pill and the grid rhythm dies,
  // which is why the previous 32 came down.
  static const radiusSm = 4.0;
  static const radiusDefault = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 20.0;

  /// Cards, sheets, hero panels — the app's signature soft corner, and the top
  /// of the brief's range.
  static const radius2xl = 24.0;
  static const radiusFull = 9999.0;

  // --- Spacing (4px base, 8px rhythm) --------------------------------------
  static const spacingUnit = 8.0;
  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space5 = 20.0;
  static const space6 = 24.0;
  static const space8 = 32.0;
  static const space10 = 40.0;

  /// Left/right page margin. Every screen uses this — it is what makes
  /// separate screens read as one app. Wide on purpose: whitespace is the
  /// single cheapest way a layout reads as expensive.
  static const screenPadding = 24.0;
  static const cardPadding = 20.0;

  /// Gap between bento tiles. Deliberately smaller than [screenPadding] so the
  /// grid reads as one compartmented tray inside a generous margin, rather
  /// than as loose cards drifting on a page.
  static const gutter = 16.0;

  /// Clearance the scrolling content must leave for the floating nav bar.
  static const navBarClearance = 120.0;

  // --- Touch ---------------------------------------------------------------
  /// WCAG 2.2 / Material minimum interactive size.
  static const minTouchTarget = 48.0;

  // --- Typography ----------------------------------------------------------
  /// Latin: a geometric grotesque with soft curves. Thai has no coverage in it,
  /// so [fontFamilyThai] is registered as the fallback — see `AppTheme`.
  static const fontFamilyName = 'Plus Jakarta Sans';
  static const fontFamilyThai = 'IBM Plex Sans Thai';
}
