import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/prefs.dart';
import 'app_theme.dart';
import 'material_scheme.dart';

/// How much contrast the user wants. These are the three variants Material
/// Theme Builder exported alongside the standard scheme — shipping them is
/// what makes "high contrast" a real setting instead of a filter we invent at
/// runtime.
enum AppContrast { standard, medium, high }

extension AppContrastLabel on AppContrast {
  String get thaiLabel => switch (this) {
        AppContrast.standard => 'มาตรฐาน',
        AppContrast.medium => 'ชัดขึ้น',
        AppContrast.high => 'ชัดสูงสุด',
      };
}

extension AppThemeModeLabel on ThemeMode {
  String get thaiLabel => switch (this) {
        ThemeMode.system => 'ตามระบบ',
        ThemeMode.light => 'สว่าง',
        ThemeMode.dark => 'มืด',
      };
}

@immutable
class ThemeState {
  /// Opens light unless the user says otherwise.
  ///
  /// `ThemeMode.system` was the old default, which meant anyone on a dark-set
  /// phone never saw the Japandi cream palette the app is actually designed
  /// around — the light scheme is the reference design, dark is the accommodation.
  /// `ตามระบบ` is still one tap away in the theme sheet for anyone who wants it.
  const ThemeState({
    this.mode = ThemeMode.light,
    this.contrast = AppContrast.standard,
  });

  final ThemeMode mode;
  final AppContrast contrast;

  ColorScheme get lightScheme => switch (contrast) {
        AppContrast.standard => MaterialSchemes.light,
        AppContrast.medium => MaterialSchemes.lightMediumContrast,
        AppContrast.high => MaterialSchemes.lightHighContrast,
      };

  ColorScheme get darkScheme => switch (contrast) {
        AppContrast.standard => MaterialSchemes.dark,
        AppContrast.medium => MaterialSchemes.darkMediumContrast,
        AppContrast.high => MaterialSchemes.darkHighContrast,
      };

  ThemeData get lightTheme => AppTheme.buildTheme(lightScheme);
  ThemeData get darkTheme => AppTheme.buildTheme(darkScheme);

  ThemeState copyWith({ThemeMode? mode, AppContrast? contrast}) =>
      ThemeState(mode: mode ?? this.mode, contrast: contrast ?? this.contrast);
}

/// Owns the two knobs the user can turn. Both light and dark themes are handed
/// to `MaterialApp` at once and `themeMode` picks between them, so
/// `ThemeMode.system` follows the OS live — the previous build derived a
/// single palette from a network image at launch, which meant the OS setting
/// was ignored and the app's colors depended on whether a CDN answered.
///
/// The choice is persisted. Without that, picking "มืด" held only until the
/// app was killed, which reads as the setting being broken rather than as
/// the app forgetting.
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier(this._prefs) : super(const ThemeState()) {
    _restore();
  }

  final SharedPreferences _prefs;

  void _restore() {
    final mode = _prefs.getString(PrefKeys.themeMode);
    final contrast = _prefs.getString(PrefKeys.themeContrast);
    state = ThemeState(
      mode: ThemeMode.values.firstWhere(
        (m) => m.name == mode,
        orElse: () => const ThemeState().mode,
      ),
      contrast: AppContrast.values.firstWhere(
        (c) => c.name == contrast,
        orElse: () => const ThemeState().contrast,
      ),
    );
  }

  void setMode(ThemeMode mode) {
    state = state.copyWith(mode: mode);
    _prefs.setString(PrefKeys.themeMode, mode.name);
  }

  void setContrast(AppContrast contrast) {
    state = state.copyWith(contrast: contrast);
    _prefs.setString(PrefKeys.themeContrast, contrast.name);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(ref.watch(sharedPreferencesProvider)),
);
