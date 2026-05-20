import 'package:flutter/material.dart';
import 'package:zuru/config/colors.dart';

class RadarGridPainter extends CustomPainter {
  const RadarGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.mapGrid
      ..strokeWidth = 0.6;

    const cellSize = 52.0;

    for (double x = 0; x <= size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(RadarGridPainter _) => false;
}
