import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// The "Vibrant Mesh Gradient" backdrop from the Brand & Style section:
/// a twilight-to-sunset base wash with a few large, heavily blurred
/// color blobs layered on top so it reads as a soft mesh rather than a
/// flat linear gradient. Every screen sits on top of exactly one of
/// these — glass cards need something colorful behind them to blur.
class MeshBackground extends StatelessWidget {
  const MeshBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base wash: deep twilight purple fading into near-black at the edges.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B1030), // near-black twilight
                DesignTokens.secondary, // Twilight Purple
                Color(0xFF2A0F14), // deep shadow
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        _Blob(
          alignment: const Alignment(-0.8, -0.9),
          diameter: 420,
          color: DesignTokens.primary, // Solaris Red
        ),
        _Blob(
          alignment: const Alignment(0.9, -0.3),
          diameter: 380,
          color: DesignTokens.tertiaryContainer, // Dawn Orange
        ),
        _Blob(
          alignment: const Alignment(0.6, 1.0),
          diameter: 460,
          color: DesignTokens.secondaryContainer, // Twilight Purple, brighter
        ),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.alignment,
    required this.diameter,
    required this.color,
  });

  final Alignment alignment;
  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}
