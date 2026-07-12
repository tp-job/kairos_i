import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/weather_service.dart';
import '../models/weather_model.dart';

/// Provider = a "store" Riverpod builds and caches for you. This one
/// just constructs the service once, wiring in the shared Dio instance.
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService(ref.watch(dioProvider));
});

/// FutureProvider is the Riverpod equivalent of react-query's useQuery:
/// call the service, and expose the result as `AsyncValue<WeatherModel>`
/// (loading / error / data) to any widget that watches it.
final weatherProvider = FutureProvider<WeatherModel>((ref) async {
  final service = ref.watch(weatherServiceProvider);
  return service.getCurrentWeather();
});
