// The forecast strip used to be hardcoded — `fri` was always snow, in
// Bangkok. These cover the aggregation that replaced it: OpenWeatherMap's
// free feed is 3-hourly for five days, and the daily endpoint is paid, so
// collapsing 3-hourly readings into one entry per day is our logic to get
// right.

import 'package:flutter_test/flutter_test.dart';

import 'package:kairos_i/features/weather/models/weather_model.dart';

/// One 3-hourly entry in the shape `/forecast` returns.
Map<String, dynamic> _entry({
  required DateTime at,
  required String condition,
  required double temp,
}) =>
    {
      'dt': at.toUtc().millisecondsSinceEpoch ~/ 1000,
      'main': {'temp_max': temp, 'temp_min': temp},
      'weather': [
        {'main': condition},
      ],
    };

Map<String, dynamic> _feed(List<Map<String, dynamic>> entries) =>
    {'list': entries};

void main() {
  group('DailyForecast.fromForecastJson', () {
    test('collapses 3-hourly entries into one entry per calendar day', () {
      final day1 = DateTime(2026, 8, 19, 9);
      final day2 = DateTime(2026, 8, 20, 9);

      final days = DailyForecast.fromForecastJson(_feed([
        _entry(at: day1, condition: 'Clear', temp: 31),
        _entry(at: day1.add(const Duration(hours: 3)), condition: 'Clear', temp: 33),
        _entry(at: day2, condition: 'Rain', temp: 28),
      ]));

      expect(days.length, 2);
      expect(days.first.date, DateTime(2026, 8, 19));
      expect(days.last.date, DateTime(2026, 8, 20));
    });

    test('days come back in chronological order regardless of feed order', () {
      final days = DailyForecast.fromForecastJson(_feed([
        _entry(at: DateTime(2026, 8, 21, 12), condition: 'Rain', temp: 27),
        _entry(at: DateTime(2026, 8, 19, 12), condition: 'Clear', temp: 33),
        _entry(at: DateTime(2026, 8, 20, 12), condition: 'Clouds', temp: 30),
      ]));

      expect(
        days.map((d) => d.date.day),
        [19, 20, 21],
      );
    });

    // The reason the midday rule exists: a 03:00 reading is very often
    // "Clear" simply because the sun is down. Taking the first entry of the
    // day would label a storm day as sunny.
    test('takes the condition nearest midday, not the first of the day', () {
      final day = DateTime(2026, 8, 19);

      final days = DailyForecast.fromForecastJson(_feed([
        _entry(at: day.add(const Duration(hours: 3)), condition: 'Clear', temp: 26),
        _entry(at: day.add(const Duration(hours: 12)), condition: 'Thunderstorm', temp: 30),
        _entry(at: day.add(const Duration(hours: 21)), condition: 'Clear', temp: 27),
      ]));

      expect(days.single.condition, 'Thunderstorm');
    });

    test('high and low span the whole day, not just the midday reading', () {
      final day = DateTime(2026, 8, 19);

      final days = DailyForecast.fromForecastJson(_feed([
        _entry(at: day.add(const Duration(hours: 6)), condition: 'Clear', temp: 24),
        _entry(at: day.add(const Duration(hours: 12)), condition: 'Clear', temp: 35),
        _entry(at: day.add(const Duration(hours: 18)), condition: 'Clear', temp: 29),
      ]));

      expect(days.single.highC, 35);
      expect(days.single.lowC, 24);
    });

    test('a single-entry day still produces a usable forecast', () {
      // The last day of the feed is usually truncated to one or two entries.
      final days = DailyForecast.fromForecastJson(_feed([
        _entry(at: DateTime(2026, 8, 23, 3), condition: 'Rain', temp: 26),
      ]));

      expect(days.single.condition, 'Rain');
      expect(days.single.highC, 26);
      expect(days.single.lowC, 26);
    });
  });
}
