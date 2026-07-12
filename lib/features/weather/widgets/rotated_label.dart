import 'package:flutter/material.dart';

/// The "S U N N Y" tag from the reference, rotated 90° so it reads
/// bottom-to-top. RotatedBox rotates the widget AND its bounding box
/// (so layout sees a tall narrow thing), which is what we want here —
/// Transform.rotate would rotate the paint but leave the box wide.
class RotatedLabel extends StatelessWidget {
  const RotatedLabel({
    super.key,
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 3, // 3 * 90° = -90° (reads bottom-up)
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          // Wide letter-spacing sells the "typeset" editorial feel.
          letterSpacing: 4,
        ),
      ),
    );
  }
}
