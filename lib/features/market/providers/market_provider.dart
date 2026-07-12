import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/market_service.dart';
import '../models/market_model.dart';

final marketServiceProvider = Provider<MarketService>((ref) {
  return MarketService(ref.watch(dioProvider));
});

/// Custom Watchlist Display (Feature 6.1) — edit this list to whatever
/// tickers matter to you. Kept as a plain provider so it's easy to
/// later swap for a user-editable setting.
final watchlistSymbolsProvider = Provider<List<String>>((ref) {
  return const ['AAPL', 'NVDA', 'MSFT'];
});

final marketProvider = FutureProvider<List<MarketQuote>>((ref) async {
  final service = ref.watch(marketServiceProvider);
  final symbols = ref.watch(watchlistSymbolsProvider);
  return service.getWatchlist(symbols);
});
