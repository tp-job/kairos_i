import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';
import 'kairos_palette.dart';
import 'material_scheme.dart';
import 'weather_palettes.dart';

/// Turns a [ColorScheme] from `material_scheme.dart` into the app's
/// [ThemeData]. Keep the mapping mechanical — a design decision belongs in the
/// Material Theme Builder export, not here.
///
/// Everything a screen needs comes out of `Theme.of(context)`: roles from
/// `colorScheme`, the extras from [KairosPalette], type from `textTheme`,
/// component defaults from the component themes below. A widget that reaches
/// for a literal `Color` is a bug — it will be wrong in one of the six
/// supported variants (light/dark × three contrast levels).
class AppTheme {
  AppTheme._();

  static ThemeData get light => buildTheme(MaterialSchemes.light);
  static ThemeData get dark => buildTheme(MaterialSchemes.dark);

  /// The standard raised surface: card rows, sheets, placeholders, skeletons.
  /// Defined once so every "soft card" in the app is literally the same
  /// decoration.
  static BoxDecoration softCard(
    BuildContext context, {
    double radius = DesignTokens.radiusXl,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final palette = KairosPalette.of(context);
    return BoxDecoration(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: scheme.outlineVariant, width: 1),
      // Wide, faint, barely offset — a diffused daylight shadow, not a drop
      // shadow. On a cream page anything darker or tighter reads as grime.
      boxShadow: [
        BoxShadow(
          color: palette.shadow,
          blurRadius: 28,
          offset: const Offset(0, 8),
          spreadRadius: -10,
        ),
      ],
    );
  }

  /// A sunken surface: inputs, wells, inactive tracks, quiet chips.
  static BoxDecoration sunkenCard(
    BuildContext context, {
    double radius = DesignTokens.radiusXl,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: scheme.outlineVariant, width: 1),
    );
  }

  static ThemeData buildTheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final base = ThemeData(brightness: scheme.brightness, useMaterial3: true);
    final palette = KairosPalette.fromScheme(scheme);
    final textTheme = _textTheme(base.textTheme, scheme);

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: [palette, WeatherPalettes.fromScheme(scheme)],
      // A soft ripple, not Material's sparkle: the sparkle's specular grain is
      // a *tech* gesture and it fights every other surface in this system.
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,

      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 24),
      primaryIconTheme: IconThemeData(color: scheme.onPrimary),

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
      ),

      // Buttons: one shape, one minimum height (48px — the accessible touch
      // target), so nothing has to restate them. The pill is the app's one
      // deliberately playful shape — every other surface is a soft-cornered
      // box, so the fully-round control is what reads as "tap me".
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, DesignTokens.minTouchTarget),
          textStyle: textTheme.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.surfaceContainerLowest,
          foregroundColor: scheme.onSurface,
          elevation: 0,
          minimumSize: const Size(64, DesignTokens.minTouchTarget),
          textStyle: textTheme.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(64, DesignTokens.minTouchTarget),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: scheme.outline),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, DesignTokens.minTouchTarget),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          minimumSize: const Size.square(DesignTokens.minTouchTarget),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        shape: const CircleBorder(),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3 + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surfaceContainerLow,
        showDragHandle: true,
        dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: 0.4),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radius2xl),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium
            ?.copyWith(color: scheme.onSurfaceVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium
            ?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primary,
        labelStyle: textTheme.labelLarge,
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space3,
          vertical: DesignTokens.space2,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: Colors.transparent,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusDefault),
        ),
        textStyle: textTheme.bodySmall
            ?.copyWith(color: scheme.onInverseSurface),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
        ),
      ),
    );
  }

  /// Plus Jakarta Sans for Latin, IBM Plex Sans Thai as the fallback for Thai.
  ///
  /// One family cannot serve this brief: the geometric grotesque it asks for
  /// has no Thai coverage, and every Thai face that does looks nothing like it
  /// in Latin. Registering the Thai face as `fontFamilyFallback` gets both —
  /// the engine picks per-glyph, so a mixed "งาน 3 รายการ" string renders
  /// Jakarta digits beside Plex Thai loops, at matching optical weight.
  ///
  /// Applied across the whole ramp — including `labelLarge`, which every button
  /// reads. Setting only a handful of styles leaves the rest on Roboto, which
  /// is why buttons and dialogs used to look like a different app.
  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    final thai = GoogleFonts.ibmPlexSansThai().fontFamily;
    final t = GoogleFonts.plusJakartaSansTextTheme(base)
        .apply(fontFamilyFallback: [?thai]);

    return t
        .copyWith(
          // Quiet luxury is *lightness*, not weight. The display sizes stay
          // large — they are still the page's only ornament — but they drop
          // from w800/-1.2 to w600/-0.4: an airy headline reads as expensive,
          // a heavy one reads as a sale banner. Leading stays near 1.1 so a
          // two-line title still reads as one block.
          displayLarge: t.displayLarge?.copyWith(
            fontSize: 44,
            height: 48 / 44,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.8,
          ),
          displayMedium: t.displayMedium?.copyWith(
            fontSize: 36,
            height: 40 / 36,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          headlineMedium: t.headlineMedium?.copyWith(
            fontSize: 28,
            height: 34 / 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          headlineSmall: t.headlineSmall?.copyWith(
            fontSize: 22,
            height: 30 / 22,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: t.titleLarge?.copyWith(
            fontSize: 20,
            height: 28 / 20,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: t.titleMedium?.copyWith(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: t.titleSmall?.copyWith(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
          ),
          // Body leading is looser than Material's default. Airiness is a
          // typographic property before it is a spacing one.
          bodyLarge: t.bodyLarge?.copyWith(fontSize: 16, height: 26 / 16),
          bodyMedium: t.bodyMedium?.copyWith(fontSize: 14, height: 22 / 14),
          bodySmall: t.bodySmall?.copyWith(fontSize: 12, height: 18 / 12),
          // Labels keep a hair of positive tracking — small text in a
          // geometric face needs the air to stay legible.
          labelLarge: t.labelLarge?.copyWith(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          labelMedium: t.labelMedium?.copyWith(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          labelSmall: t.labelSmall?.copyWith(
            fontSize: 11,
            height: 16 / 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        )
        .apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );
  }
}

/// Shorthand for the three lookups every widget does.
///
/// `context.colors.primary`, `context.text.titleMedium`,
/// `context.palette.heroGradient`.
extension ThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  KairosPalette get palette => KairosPalette.of(this);
  WeatherPalettes get skies => WeatherPalettes.of(this);
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
}
