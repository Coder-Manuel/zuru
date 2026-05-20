import 'dart:math';
import 'package:flutter/material.dart';
import 'package:zuru/config/colors.dart';

class RadarSweepPainter extends CustomPainter {
  final double rotation; // 0 → 2π

  const RadarSweepPainter({required this.rotation});

  static const _sweepSpan = pi * 0.5; // 90° trailing sector
  static const _steps = 32; // number of gradient slices

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = max(size.width, size.height) * 1.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final sweepRect = Rect.fromCenter(
      center: Offset.zero,
      width: radius * 2,
      height: radius * 2,
    );

    // ── Gradient sector: thin slices from transparent (tail) → opaque (lead) ─
    // Using manual slices instead of SweepGradient so the fade is reliable
    // regardless of angle wrapping.
    final sliceSpan = _sweepSpan / _steps + 0.002; // tiny overlap avoids gaps
    final paint = Paint();

    for (int i = 0; i < _steps; i++) {
      final t = (i + 1) / _steps; // 0 at tail → 1 at leading edge
      final sliceStart = -_sweepSpan + (i / _steps) * _sweepSpan;

      // Quadratic ease-in: nearly invisible at the tail, muted at the edge
      final alpha = (t * t * 35).round().clamp(0, 255);

      canvas.drawArc(
        sweepRect,
        sliceStart,
        sliceSpan,
        true, // useCenter → filled pie slice
        paint..color = AppColors.primary.withAlpha(alpha),
      );
    }

    // ── Leading sweep line ───────────────────────────────────────────────────
    canvas.drawLine(
      Offset.zero,
      Offset(radius, 0),
      Paint()
        ..color = AppColors.primary.withAlpha(40)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(RadarSweepPainter old) => old.rotation != rotation;
}
