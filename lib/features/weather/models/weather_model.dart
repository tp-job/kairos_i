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
