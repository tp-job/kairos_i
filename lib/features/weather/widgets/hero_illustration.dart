import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/weather_condition.dart';
import 'horizon_lines.dart';

/// Big illustration in the middle of the detail screen. Composes:
///  1. The SVG for the current condition (sun/cloud/moon + birds)
///  2. Horizon reflection lines drawn just under it
///
/// Reads only from [WeatherCondition] — never from raw API strings —
/// so swapping the API later doesn't affect this widget.
class HeroIllustration extends StatelessWidget {
  const HeroIllustration({super.key, required this.condition});

  final WeatherCondition condition;

  @override
  Widget build(BuildContext context) {
    final palette = condition.palette;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth * 0.7;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                condition.assetPath,
                width: size,
                height: size,
              ),
              // Slight negative gap so the top-most horizon line touches
              // the wave silhouette in the SVG.
              Transform.translate(
                offset: const Offset(0, -8),
                child: SizedBox(
                  width: size * 0.9,
                  height: 40,
                  child: HorizonLines(color: palette.accent),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
