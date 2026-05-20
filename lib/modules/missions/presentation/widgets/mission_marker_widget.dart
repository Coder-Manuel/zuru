import 'package:flutter/material.dart';
import 'package:zuru/config/scout_colors.dart';

class MissionMarkerWidget extends StatefulWidget {
  final String price;

  const MissionMarkerWidget({required this.price, super.key});

  @override
  State<MissionMarkerWidget> createState() => _MissionMarkerWidgetState();
}

class _MissionMarkerWidgetState extends State<MissionMarkerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) =>
                CustomPaint(painter: _RippleDotPainter(progress: _ctrl.value)),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: ScoutColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ScoutColors.divider, width: 0.8),
          ),
          child: Text(
            widget.price,
            style: const TextStyle(
              color: ScoutColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _RippleDotPainter extends CustomPainter {
  final double progress;

  const _RippleDotPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Three staggered expanding rings
    for (int i = 0; i < 3; i++) {
      final t = (progress + i / 3.0) % 1.0;
      final radius = 7.0 + t * 19.0;
      final opacity = (1.0 - t) * 0.55;
      if (opacity <= 0) continue;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = ScoutColors.primary.withAlpha((opacity * 255).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    // Core glowing dot
    canvas.drawCircle(
      center,
      6.5,
      Paint()
        ..color = ScoutColors.primary
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(center, 5.0, Paint()..color = ScoutColors.primary);
  }

  @override
  bool shouldRepaint(_RippleDotPainter old) => old.progress != progress;
}
