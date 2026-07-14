import 'package:dio/dio.dart';
import '../../../core/env/env.dart';
import '../models/weather_model.dart';

/// Talks to OpenWeatherMap only. No Flutter/Riverpod imports here on
/// purpose — a service is a plain Dart class you could unit-test or
/// reuse in a CLI tool.
class WeatherService {
  WeatherService(this._dio);

  final Dio _dio;

  static const _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  /// [lat]/[lon] come from device geolocation in a real app; hardcode
  /// Bangkok here so the template runs without location permissions.
  ///
  /// Two requests run in parallel: the Thai one supplies the weather
  /// description + Thai city name, the English one supplies just the
  /// English city name so the UI can show the location bilingually.
  Future<WeatherModel> getCurrentWeather({
    double lat = 13.7563,
    double lon = 100.5018,
  }) async {
    final results = await Future.wait([
      _fetch(lat: lat, lon: lon, lang: 'th'),
      _fetch(lat: lat, lon: lon, lang: 'en'),
    ]);

    final thai = results[0];
    final english = results[1];

    return WeatherModel.fromJson(
      thai,
      cityNameEn: english['name'] as String?,
    );
  }

  Future<Map<String, dynamic>> _fetch({
    required double lat,
    required double lon,
    required String lang,
  }) async {
    final response = await _dio.get(
      _baseUrl,
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'appid': Env.openWeatherApiKey,
        'units': 'metric',
        'lang': lang,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
