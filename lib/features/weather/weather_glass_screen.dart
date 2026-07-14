import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/weather_provider.dart';
import 'widgets/weather_detail_screen.dart';

/// Glassmorphism weather page — the "New York" main interface from the
/// `weather` reference: a slate gradient card, a big temperature, a 2×2
/// detail grid of frosted pills, and a simplified hourly trend graph.
///
/// Bound to [weatherProvider] for the live city, temperature, feels-like
/// and humidity; the remaining figures (wind, UV, pressure, hourly points)
/// are the reference's sample values until a forecast API is wired.
class WeatherGlassScreen extends ConsumerWidget {
  const WeatherGlassScreen({super.key});

  static const _gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF64748B),
      body: Container(
        decoration: const BoxDecoration(gradient: _gradient),
        child: SafeArea(
          child: weather.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (_, _) => const _Body(
              city: 'New York',
              tempC: 10,
              feelsLikeC: 9,
              humidity: 78,
              description: 'Clear & Sunny',
            ),
            data: (data) => _Body(
              city: data.cityNameEn ?? data.cityName,
              tempC: data.temperatureC,
              feelsLikeC: data.feelsLikeC,
              humidity: data.humidityPercent,
              description: data.description,
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.city,
    required this.tempC,
    required this.feelsLikeC,
    required this.humidity,
    required this.description,
  });

  final String city;
  final double tempC;
  final double feelsLikeC;
  final int humidity;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(TimeOfDay.now().format(context),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(city, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w400)),
                    const SizedBox(height: 12),
                    Text(_titleCase(description),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
                  ],
                ),
              ),
              _GlassPill(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Opens the alternate editorial weather view.
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WeatherDetailScreen()),
                      ),
                      behavior: HitTestBehavior.opaque,
                      child: const Icon(Icons.settings, color: Colors.white70, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const SizedBox(height: 16, width: 1, child: ColoredBox(color: Colors.white30)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      behavior: HitTestBehavior.opaque,
                      child: const Icon(Icons.home_outlined, color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Big temperature.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 48),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${tempC.round()}°',
                      style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w300, height: 1)),
                  Text('/ Real Feel ${feelsLikeC.round()}°',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Details header.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('DETAILS:',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  )),
              const _GlassPill(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('weatherglobal.com', style: TextStyle(color: Colors.white, fontSize: 12)),
                    SizedBox(width: 4),
                    Icon(Icons.open_in_new, color: Colors.white, size: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 2×2 detail grid.
          Row(
            children: [
              Expanded(child: _Detail(icon: Icons.arrow_forward, label: 'Wind', value: '3.4 km/h')),
              SizedBox(width: 16),
              Expanded(child: _Detail(icon: Icons.water_drop_outlined, label: 'Humidity', value: '$humidity%')),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: _Detail(icon: Icons.wb_sunny_outlined, label: 'UV Index', value: '2')),
              SizedBox(width: 16),
              Expanded(child: _Detail(icon: Icons.bolt, label: 'Pressure', value: '1016hpa')),
            ],
          ),
          const Spacer(),
          // Hourly trend.
          const _HourlyTrend(),
        ],
      ),
    );
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }
}

// --- Frosted pill primitive ------------------------------------------------

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GlassPill(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w400)),
      ],
    );
  }
}

// --- Hourly trend ----------------------------------------------------------

class _HourPoint {
  const _HourPoint(this.label, this.temp, this.icon, this.level);
  final String label;
  final String temp;
  final IconData icon;

  /// 0..1 vertical position used to draw the trend line (1 = warmest/top).
  final double level;
}

class _HourlyTrend extends StatelessWidget {
  const _HourlyTrend();

  static const _points = <_HourPoint>[
    _HourPoint('Now', '10°', Icons.wb_sunny_outlined, 1.0),
    _HourPoint('22:00', '9°', Icons.nightlight_round, 0.75),
    _HourPoint('23:00', '8°', Icons.cloud_outlined, 0.5),
    _HourPoint('00:00', '6°', Icons.cloud_outlined, 0.2),
    _HourPoint('01:00', '6°', Icons.cloud_outlined, 0.2),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _TrendPainter(_points.map((p) => p.level).toList())),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final p in _points)
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(p.temp, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                    const SizedBox(height: 20),
                    Icon(p.icon, color: Colors.white.withValues(alpha: 0.85), size: 16),
                    const SizedBox(height: 4),
                    Text(p.label, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Draws the faint connecting line + dots across the hourly points. The
/// [levels] (0..1) are mapped into the top ~40px band so the line sits
/// above the temperature labels.
class _TrendPainter extends CustomPainter {
  _TrendPainter(this.levels);
  final List<double> levels;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.length < 2) return;
    const bandTop = 4.0;
    const bandHeight = 36.0;
    final dx = size.width / (levels.length - 1);

    Offset pointAt(int i) => Offset(dx * i, bandTop + (1 - levels[i]) * bandHeight);

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < levels.length; i++) {
      final prev = pointAt(i - 1);
      final curr = pointAt(i);
      final midX = (prev.dx + curr.dx) / 2;
      path.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(path, line);

    final dot = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < levels.length; i++) {
      canvas.drawCircle(pointAt(i), 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => oldDelegate.levels != levels;
}
