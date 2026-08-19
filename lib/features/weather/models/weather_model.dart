/// Plain Dart class with manual fromJson — no code generation, so you
/// can see exactly how a raw HTTP response becomes a typed object.
/// (In a bigger app you'd reach for freezed/json_serializable instead
/// of writing this by hand every time.)
class WeatherModel {
  const WeatherModel({
    required this.cityName,
    this.cityNameEn,
    required this.temperatureC,
    required this.feelsLikeC,
    required this.condition,
    required this.description,
    required this.rainChancePercent,
    required this.humidityPercent,
  });

  /// Localized city name (Thai, from `lang=th`) — e.g. "จังหวัดนนทบุรี".
  final String cityName;

  /// English city name (from a parallel `lang=en` request), when available —
  /// e.g. "Nonthaburi". Null if the English lookup wasn't made or matched
  /// the Thai name.
  final String? cityNameEn;
  final double temperatureC;
  final double feelsLikeC;
  final String condition; // e.g. "Rain", "Clear"
  final String description; // e.g. "light rain"
  final int rainChancePercent; // derived from pop (0.0-1.0) when available
  final int humidityPercent;

  factory WeatherModel.fromJson(
    Map<String, dynamic> json, {
    String? cityNameEn,
  }) {
    final main = json['main'] as Map<String, dynamic>;
    final weatherList = json['weather'] as List<dynamic>;
    final weather = weatherList.first as Map<String, dynamic>;

    final name = json['name'] as String? ?? 'Unknown';
    return WeatherModel(
      cityName: name,
      // Only keep the English name when it actually differs from the Thai
      // one, so the UI doesn't render the same word twice.
      cityNameEn: (cityNameEn != null && cityNameEn != name) ? cityNameEn : null,
      temperatureC: (main['temp'] as num).toDouble(),
      feelsLikeC: (main['feels_like'] as num).toDouble(),
      condition: weather['main'] as String? ?? '',
      description: weather['description'] as String? ?? '',
      // OpenWeatherMap's /weather endpoint doesn't return pop directly;
      // approximate risk from humidity + cloud cover for this current-conditions card.
      rainChancePercent: ((json['clouds']?['all'] as num?)?.toInt() ?? 0),
      humidityPercent: (main['humidity'] as num).toInt(),
    );
  }

  /// True when it's worth surfacing a proactive alert (Feature 4:
  /// AI Smart Alert) — kept as a simple rule here; the Orchestrator
  /// feature can layer AI reasoning on top of this raw signal.
  bool get isRiskyForOutdoorPlans =>
      condition == 'Rain' || condition == 'Thunderstorm' || rainChancePercent > 70;
}

/// One day in the forecast strip.
///
/// The strip used to be a hardcoded list — `tue` was always cool, `fri` was
/// always snow — so the day selector confidently showed snow in Bangkok.
/// This is the real thing.
class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.condition,
    required this.highC,
    required this.lowC,
  });

  final DateTime date;

  /// Raw OpenWeatherMap condition string ("Rain", "Clear"), mapped to a
  /// `WeatherCondition` at the UI edge exactly like current conditions are.
  final String condition;
  final double highC;
  final double lowC;

  /// Collapses OpenWeatherMap's free `/forecast` feed — 3-hourly entries for
  /// five days — into one entry per calendar day.
  ///
  /// The free tier has no daily endpoint, so the aggregation has to happen
  /// here. The day's condition is taken from the entry nearest midday rather
  /// than the first of the day: a 03:00 reading is usually "Clear" simply
  /// because the sun is down, which would label a storm day as sunny.
  static List<DailyForecast> fromForecastJson(Map<String, dynamic> json) {
    final entries = (json['list'] as List<dynamic>).cast<Map<String, dynamic>>();

    final byDay = <DateTime, List<Map<String, dynamic>>>{};
    for (final entry in entries) {
      final at = DateTime.fromMillisecondsSinceEpoch(
        (entry['dt'] as num).toInt() * 1000,
        isUtc: true,
      ).toLocal();
      final day = DateTime(at.year, at.month, at.day);
      (byDay[day] ??= []).add(entry);
    }

    final days = byDay.keys.toList()..sort();
    return [
      for (final day in days)
        DailyForecast(
          date: day,
          condition: _middayCondition(byDay[day]!),
          highC: _extreme(byDay[day]!, 'temp_max', high: true),
          lowC: _extreme(byDay[day]!, 'temp_min', high: false),
        ),
    ];
  }

  static String _middayCondition(List<Map<String, dynamic>> dayEntries) {
    Map<String, dynamic>? best;
    int? bestDistance;
    for (final entry in dayEntries) {
      final at = DateTime.fromMillisecondsSinceEpoch(
        (entry['dt'] as num).toInt() * 1000,
        isUtc: true,
      ).toLocal();
      final distance = (at.hour - 12).abs();
      if (bestDistance == null || distance < bestDistance) {
        bestDistance = distance;
        best = entry;
      }
    }
    final weather = (best!['weather'] as List<dynamic>).first
        as Map<String, dynamic>;
    return weather['main'] as String? ?? 'Clear';
  }

  static double _extreme(
    List<Map<String, dynamic>> dayEntries,
    String key, {
    required bool high,
  }) {
    final values = [
      for (final e in dayEntries)
        ((e['main'] as Map<String, dynamic>)[key] as num).toDouble(),
    ];
    return high
        ? values.reduce((a, b) => a > b ? a : b)
        : values.reduce((a, b) => a < b ? a : b);
  }
}
