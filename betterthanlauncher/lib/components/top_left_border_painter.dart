import 'package:flutter/material.dart';

class TopLeftBorderPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double radius;

  TopLeftBorderPainter({
    required this.backgroundColor,
    required this.borderColor,
    this.borderWidth = 2,
    this.radius = 20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Outer rectangle (border)
    final outer = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: Radius.circular(radius),
    );

    // Inner rectangle (background)
    final inner = RRect.fromRectAndCorners(
      Rect.fromLTWH(borderWidth, borderWidth, size.width - borderWidth, size.height - borderWidth),
      topLeft: Radius.circular(radius - borderWidth),
    );

    // Draw border
    canvas.drawRRect(outer, Paint()..color = borderColor..style = PaintingStyle.fill);

    // Draw background on top
    canvas.drawRRect(inner, Paint()..color = backgroundColor..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
