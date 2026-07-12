import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed wrapper around the raw .env map so the rest of the app never
/// touches string keys directly (and a missing key fails loudly, not
/// with a silent null deep inside some widget).
class Env {
  Env._();

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing $key in .env — copy .env.example to .env and fill it in.',
      );
    }
    return value;
  }

  static String get openRouterApiKey => _require('OPENROUTER_API_KEY');
  static String get openWeatherApiKey => _require('OPENWEATHER_API_KEY');
  static String get clickUpApiToken => _require('CLICKUP_API_TOKEN');
  static String get clickUpListId => _require('CLICKUP_LIST_ID');
  static String get gNewsApiKey => _require('GNEWS_API_KEY');
  static String get alphaVantageApiKey => _require('ALPHAVANTAGE_API_KEY');
}
