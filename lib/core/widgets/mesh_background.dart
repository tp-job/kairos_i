import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// The app canvas. In the "Studio" light theme this is simply the soft
/// off-white background; screens (their charcoal headers, white cards)
/// carry the design. Kept as a wrapper so main.dart doesn't change and we
/// can reintroduce a texture later if wanted.
class MeshBackground extends StatelessWidget {
  const MeshBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DesignTokens.background,
      child: child,
    );
  }
}
