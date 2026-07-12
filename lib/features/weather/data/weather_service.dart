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
  Future<WeatherModel> getCurrentWeather({
    double lat = 13.7563,
    double lon = 100.5018,
  }) async {
    final response = await _dio.get(
      _baseUrl,
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'appid': Env.openWeatherApiKey,
        'units': 'metric',
        'lang': 'th',
      },
    );

    return WeatherModel.fromJson(response.data as Map<String, dynamic>);
  }
}
