import 'package:dio/dio.dart';
import '../../../core/env/env.dart';
import '../models/market_model.dart';

/// Alpha Vantage free tier: 25 requests/day, so this service is
/// intentionally called for a short, fixed watchlist rather than
/// anything dynamic/search-driven.
class MarketService {
  MarketService(this._dio);

  final Dio _dio;

  static const _baseUrl = 'https://www.alphavantage.co/query';

  Future<MarketQuote> getDailySeries(String symbol) async {
    final response = await _dio.get(
      _baseUrl,
      queryParameters: {
        'function': 'TIME_SERIES_DAILY',
        'symbol': symbol,
        'apikey': Env.alphaVantageApiKey,
      },
    );

    return MarketQuote.fromAlphaVantageJson(
      symbol,
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<MarketQuote>> getWatchlist(List<String> symbols) {
    return Future.wait(symbols.map(getDailySeries));
  }
}
