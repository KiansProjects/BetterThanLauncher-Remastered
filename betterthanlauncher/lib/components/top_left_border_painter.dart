import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class TopLeftBorderPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double radius;
  final ui.Image? overlayImage;
  final double imageOpacity;

  TopLeftBorderPainter({
    required this.backgroundColor,
    required this.borderColor,
    this.borderWidth = 2,
    this.radius = 20,
    this.overlayImage,
    this.imageOpacity = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: Radius.circular(radius),
    );
    canvas.drawRRect(
      backgroundRect,
      Paint()..color = backgroundColor..style = PaintingStyle.fill,
    );

    canvas.save();
    canvas.clipRRect(backgroundRect);

    if (overlayImage != null) {
      final paint = Paint()..color = Colors.white.withOpacity(imageOpacity);
      final src = Rect.fromLTWH(
        0, 0, overlayImage!.width.toDouble(), overlayImage!.height.toDouble());
      final dst = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawImageRect(overlayImage!, src, dst, paint);
    }
    canvas.restore();

    final path = Path()
      ..moveTo(0, radius)
      ..arcToPoint(
        Offset(radius, 0),
        radius: Radius.circular(radius),
        clockwise: true,
      )
      ..lineTo(size.width, 0)
      ..moveTo(0, radius)
      ..lineTo(0, size.height);

    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
