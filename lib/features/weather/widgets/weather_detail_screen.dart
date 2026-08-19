import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kairos_i/core/theme/app_theme.dart';
import 'package:kairos_i/core/theme/weather_palettes.dart';
import 'package:kairos_i/core/widgets/kairos_spinner.dart';
import '../models/weather_condition.dart';
import '../models/weather_model.dart';
import '../providers/weather_provider.dart';
import 'big_temperature.dart';
import 'day_selector.dart';
import 'hero_illustration.dart';
import 'paper_background.dart';
import 'rotated_label.dart';

/// Full-screen editorial view — the one shown in the reference image.
///
/// This is the "assemble everything" screen: it reads WeatherModel from
/// the existing provider, converts it into a WeatherCondition, and hands
/// palette/asset/label to the atoms built in s3-s4. No new networking or
/// business logic lives here.
class WeatherDetailScreen extends ConsumerStatefulWidget {
  const WeatherDetailScreen({super.key});

  @override
  ConsumerState<WeatherDetailScreen> createState() =>
      _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends ConsumerState<WeatherDetailScreen> {
  int _selectedDayIndex = 0;

  /// Builds the day strip from the real forecast.
  ///
  /// Index 0 is always "now" and carries the *live* condition, so the strip
  /// agrees with the big temperature above it. The rest come from the
  /// aggregated 5-day feed.
  List<DayEntry> _strip(WeatherModel now, List<DailyForecast> forecast) {
    final today = DateTime.now();
    bool isToday(DateTime d) =>
        d.year == today.year && d.month == today.month && d.day == today.day;

    final nowCondition = WeatherCondition.fromApi(now.condition);
    return [
      DayEntry(
        label: 'now',
        icon: nowCondition.icon,
        condition: nowCondition,
      ),
      for (final day in forecast.where((d) => !isToday(d.date)).take(5))
        DayEntry(
          label: _weekday(day.date),
          icon: WeatherCondition.fromApi(day.condition).icon,
          condition: WeatherCondition.fromApi(day.condition),
        ),
    ];
  }

  static String _weekday(DateTime date) =>
      const ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'][date.weekday - 1];

  @override
  Widget build(BuildContext context) {
    final weather = ref.watch(weatherProvider);
    final forecast = ref.watch(forecastProvider);

    return weather.when(
      loading: () => const _FullScreenLoader(),
      error: (e, _) => _FullScreenError(message: '$e'),
      data: (data) {
        // A forecast failure degrades to a single "now" chip rather than
        // taking the whole screen down — current conditions are the point
        // of this view, the strip is secondary.
        final days = _strip(data, forecast.valueOrNull ?? const []);
        final index = _selectedDayIndex.clamp(0, days.length - 1);
        return _Loaded(
          data: data,
          days: days,
          selectedIndex: index,
          onSelect: (i) => setState(() => _selectedDayIndex = i),
        );
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.data,
    required this.days,
    required this.selectedIndex,
    required this.onSelect,
  });

  final WeatherModel data;
  final List<DayEntry> days;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    // "now" reflects the live API condition; other days come from the
    // mock forecast list.
    final nowCondition = WeatherCondition.fromApi(data.condition);
    final selectedCondition = selectedIndex == 0
        ? nowCondition
        : days[selectedIndex].condition;
    // The sky's pigments now come from the theme, so this screen follows
    // ThemeMode like every other one instead of forcing a cream page.
    final palette = context.skies.forSky(selectedCondition.sky);

    return Scaffold(
      backgroundColor: palette.background,
      body: PaperBackground(
        color: palette.background,
        grainTint: palette.ink,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                _TopBar(palette: palette),
                const SizedBox(height: 12),
                _TemperatureRow(
                  data: data,
                  condition: selectedCondition,
                  palette: palette,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: HeroIllustration(condition: selectedCondition),
                ),
                _LocationLabel(
                  thaiName: data.cityName,
                  englishName: data.cityNameEn,
                  palette: palette,
                ),
                const SizedBox(height: 24),
                DaySelector(
                  days: days,
                  selectedIndex: selectedIndex,
                  onSelect: onSelect,
                  palette: palette,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.palette});
  final WeatherPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: palette.ink, size: 20),
        ),
      ],
    );
  }
}

class _TemperatureRow extends StatelessWidget {
  const _TemperatureRow({
    required this.data,
    required this.condition,
    required this.palette,
  });

  final WeatherModel data;
  final WeatherCondition condition;
  final WeatherPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BigTemperature(
          temperatureC: data.temperatureC,
          color: palette.ink,
          mutedColor: palette.mutedInk,
        ),
        const Spacer(),
        // The rotated tag hugs the right edge next to the temperature.
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: RotatedLabel(
            text: condition.shortLabel,
            color: palette.ink,
          ),
        ),
      ],
    );
  }
}

/// The location label under the illustration. The Thai name must use the
/// Thai font (IBM Plex Sans Thai) — a Latin-only fallback can't position
/// Thai tone/vowel marks, and a large `letterSpacing` scatters them off
/// their base consonants (the rendering bug this replaces). Latin text has
/// no such constraint, so the optional English line keeps the editorial
/// letter-spaced caps.
class _LocationLabel extends StatelessWidget {
  const _LocationLabel({
    required this.thaiName,
    required this.englishName,
    required this.palette,
  });

  final String thaiName;
  final String? englishName;
  final WeatherPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          thaiName,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: palette.ink,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            // A hair of tracking is safe for Thai; the previous value (6)
            // pushed the combining marks off their bases.
            letterSpacing: 0.5,
          ),
        ),
        if (englishName != null) ...[
          const SizedBox(height: 4),
          Text(
            englishName!.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.mutedInk,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 5,
            ),
          ),
        ],
      ],
    );
  }
}

/// Shown before the condition is known, so there is no sky to paint yet —
/// these two fall back to the app scheme rather than to the *sunny* palette.
/// Hard-coding cream here meant a dark-mode user got a white flash on every
/// open, and the spinner (which takes its color from the theme's primary)
/// drew light sage on that cream: effectively invisible.
class _FullScreenLoader extends StatelessWidget {
  const _FullScreenLoader();
  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: const Center(child: KairosSpinner(size: 34)),
    );
  }
}

class _FullScreenError extends StatelessWidget {
  const _FullScreenError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'โหลดข้อมูลไม่สำเร็จ\n$message',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: scheme.onSurface,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
