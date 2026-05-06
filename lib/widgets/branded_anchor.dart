import 'package:flutter/material.dart';

class BrandedAnchor extends StatelessWidget {
  final double size;
  final Color color;

  const BrandedAnchor({
    super.key,
    this.size = 60.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    // Material anchor glyph sits low in its em-box; nudge up + inset so it reads centered in the monolith square.
    final glyph = size * 0.88;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Transform.translate(
          offset: Offset(0, -size * 0.045),
          child: Icon(
            Icons.anchor,
            size: glyph,
            color: color,
          ),
        ),
      ),
    );
  }
}
