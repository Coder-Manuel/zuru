import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zuru/config/client_colors.dart';

/// Gold "check" disc encircled by a continuously-rotating teal/green comet
/// ring — used on the "Request sent" confirmation screen.
class AnimatedSuccessRing extends StatefulWidget {
  final double size;
  const AnimatedSuccessRing({super.key, this.size = 150});

  @override
  State<AnimatedSuccessRing> createState() => _AnimatedSuccessRingState();
}

class _AnimatedSuccessRingState extends State<AnimatedSuccessRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final disc = size * 0.62;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _controller,
            child: CustomPaint(
              size: Size(size, size),
              painter: _CometRingPainter(color: ClientColors.green),
            ),
          ),
          Container(
            width: disc,
            height: disc,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ClientColors.primary,
              boxShadow: [
                BoxShadow(
                  color: ClientColors.primary.withAlpha(90),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.check_rounded,
              color: ClientColors.background,
              size: disc * 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CometRingPainter extends CustomPainter {
  final Color color;
  const _CometRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2 - 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [color.withAlpha(0), color.withAlpha(40), color.withAlpha(255)],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(rect);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 1.9,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CometRingPainter oldDelegate) => false;
}
