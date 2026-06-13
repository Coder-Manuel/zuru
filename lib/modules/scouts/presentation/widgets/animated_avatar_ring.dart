import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zuru/config/client_colors.dart';

/// Large scout avatar with a continuously-rotating green "comet" ring, a
/// static gold ring, and an optional verified badge — as on the scout profile.
class AnimatedAvatarRing extends StatefulWidget {
  final double size;
  final String initials;
  final String? imageUrl;
  final bool showVerified;

  const AnimatedAvatarRing({
    super.key,
    required this.initials,
    this.imageUrl,
    this.size = 150,
    this.showVerified = true,
  });

  @override
  State<AnimatedAvatarRing> createState() => _AnimatedAvatarRingState();
}

class _AnimatedAvatarRingState extends State<AnimatedAvatarRing>
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
    final inner = size * 0.78;
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating green comet ring.
          RotationTransition(
            turns: _controller,
            child: CustomPaint(
              size: Size(size, size),
              painter: _CometRingPainter(color: ClientColors.green),
            ),
          ),

          // Avatar disc with a static gold ring.
          Container(
            width: inner,
            height: inner,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ClientColors.inputBg,
              border: Border.all(color: ClientColors.primary, width: 2),
              image: hasImage
                  ? DecorationImage(
                      image: NetworkImage(widget.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasImage
                ? null
                : Center(
                    child: Text(
                      widget.initials,
                      style: TextStyle(
                        color: ClientColors.textPrimary,
                        fontSize: inner * 0.34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
          ),

          // Verified badge.
          if (widget.showVerified)
            Positioned(
              right: size * 0.12,
              bottom: size * 0.12,
              child: Container(
                width: size * 0.18,
                height: size * 0.18,
                decoration: BoxDecoration(
                  color: ClientColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: ClientColors.background, width: 3),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: size * 0.1,
                  color: ClientColors.background,
                ),
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
        colors: [
          color.withAlpha(0),
          color.withAlpha(40),
          color.withAlpha(255),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(rect);

    // Draw most of the circle as a fading sweep — rotation makes it a comet.
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
