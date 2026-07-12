class MarketQuote {
  const MarketQuote({
    required this.symbol,
    required this.closePrices, // oldest -> newest, for the sparkline
  });

  final String symbol;
  final List<double> closePrices;

  double get latest => closePrices.last;
  double get previous =>
      closePrices.length > 1 ? closePrices[closePrices.length - 2] : latest;
  double get changePercent =>
      previous == 0 ? 0 : ((latest - previous) / previous) * 100;
  bool get isUp => changePercent >= 0;

  /// Alpha Vantage's TIME_SERIES_DAILY response is a map keyed by date
  /// string, newest first — we reverse it so the chart reads left-to-right.
  factory MarketQuote.fromAlphaVantageJson(
    String symbol,
    Map<String, dynamic> json,
  ) {
    final series = json['Time Series (Daily)'] as Map<String, dynamic>;
    final sortedDates = series.keys.toList()..sort(); // ascending
    final lastTenDates = sortedDates.length > 10
        ? sortedDates.sublist(sortedDates.length - 10)
        : sortedDates;
    final closes = lastTenDates
        .map((date) => double.parse(series[date]['4. close'] as String))
        .toList();

    return MarketQuote(symbol: symbol, closePrices: closes);
  }
}
