import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The "26 °C" title from the reference. Two-line typography: the big
/// number on top-left, then "° / C" stacked vertically on its right —
/// like a chemistry unit rather than a normal temperature label.
class BigTemperature extends StatelessWidget {
  const BigTemperature({
    super.key,
    required this.temperatureC,
    required this.color,
    required this.mutedColor,
  });

  final double temperatureC;
  final Color color;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final numberStyle = GoogleFonts.ibmPlexSansThai(
      fontSize: 96,
      fontWeight: FontWeight.w500,
      height: 1.0,
      color: color,
      letterSpacing: -2,
    );
    final unitStyle = GoogleFonts.ibmPlexSansThai(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      height: 1.1,
      color: mutedColor,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(temperatureC.round().toString(), style: numberStyle),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('°', style: unitStyle),
              Text('C', style: unitStyle),
            ],
          ),
        ),
      ],
    );
  }
}
