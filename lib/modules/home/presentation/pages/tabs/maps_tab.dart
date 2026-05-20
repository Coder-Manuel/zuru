import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/colors.dart';
import 'package:zuru/modules/home/presentation/controllers/maps_tab_controller.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/presentation/pages/post_mission_page.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

class MapsTab extends StatelessWidget {
  const MapsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MapView();
  }
}

// ─── Map view ─────────────────────────────────────────────────────────────────

class _MapView extends StatelessWidget {
  const _MapView();

  // Map area occupies the upper portion of the screen
  static const _mapHeightFraction = 0.72;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<MapsTabController>();
    final size = Get.mediaQuery.size;
    final mapHeight = size.height * _mapHeightFraction;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Grid background ──────────────────────────────────────────────
            CustomPaint(
              size: Size(size.width, size.height),
              painter: _GridPainter(),
            ),

            // ── Mission markers (real-time) ──────────────────────────────────
            Obx(() {
              final missions = ctrl.activeMissions
                  .where((m) => m.latitude != null && m.longitude != null)
                  .toList();

              if (missions.isEmpty) return const SizedBox.shrink();

              final (clat, clng) = _centroid(missions);
              final scale = _scaleFor(
                missions,
                clat,
                clng,
                size.width,
                mapHeight,
              );

              // Centre of the "map" viewport
              final cx = size.width * 0.50;
              final cy = mapHeight * 0.50;

              return Stack(
                children: [
                  for (int i = 0; i < missions.length; i++)
                    Builder(
                      builder: (_) {
                        final m = missions[i];
                        final px = cx + (m.longitude! - clng) * scale;
                        // Invert latitude: north is up on screen
                        final py = cy - (m.latitude! - clat) * scale;

                        // Clamp so labels don't clip off-screen
                        final clampedX = px.clamp(32.0, size.width - 32.0);
                        final clampedY = py.clamp(60.0, mapHeight - 20.0);

                        return Positioned(
                          left: clampedX - 9, // centre the 18-px dot
                          top: clampedY - 50, // label + gap sit above dot
                          child: _MissionMarker(mission: m, staggerMs: i * 400),
                        );
                      },
                    ),
                ],
              );
            }),

            // ── User location dot (teal) ─────────────────────────────────────
            Positioned(
              left: size.width * 0.50 - 7,
              top: mapHeight * 0.50 - 7,
              child: const _UserDot(),
            ),

            // ── Bottom overlay ───────────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomOverlay(ctrl: ctrl),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static (double, double) _centroid(List<MissionEntity> missions) {
    final lat =
        missions.map((m) => m.latitude!).reduce((a, b) => a + b) /
        missions.length;
    final lng =
        missions.map((m) => m.longitude!).reduce((a, b) => a + b) /
        missions.length;
    return (lat, lng);
  }

  /// Returns a pixels-per-degree scale so the outermost mission sits at ~38 %
  /// of the half-width/half-height of the map area, keeping all dots well
  /// inside the grid and away from the bottom overlay.
  static double _scaleFor(
    List<MissionEntity> missions,
    double clat,
    double clng,
    double mapWidth,
    double mapHeight,
  ) {
    double maxDegOffset = 0.005; // ~550 m minimum to avoid collapsing to center
    for (final m in missions) {
      final dx = (m.longitude! - clng).abs();
      final dy = (m.latitude! - clat).abs();
      if (dx > maxDegOffset) maxDegOffset = dx;
      if (dy > maxDegOffset) maxDegOffset = dy;
    }

    // Target: farthest mission sits at ~38 % of half-dimension
    final scaleX = (mapWidth * 0.38) / maxDegOffset;
    final scaleY = (mapHeight * 0.38) / maxDegOffset;
    return min(scaleX, scaleY);
  }
}

// ─── Pulsating mission marker ────────────────────────────────────────────────

class _MissionMarker extends StatefulWidget {
  final MissionEntity mission;
  final int staggerMs;

  const _MissionMarker({required this.mission, required this.staggerMs});

  @override
  State<_MissionMarker> createState() => _MissionMarkerState();
}

class _MissionMarkerState extends State<_MissionMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  Color get _color => switch (widget.mission.status) {
    MissionStatus.live => const Color(0xFFEF4444),
    MissionStatus.accepted || MissionStatus.enroute => AppColors.primaryDark,
    _ => AppColors.primary,
  };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 3.2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(
      begin: 0.55,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.staggerMs), () {
      if (mounted) _ctrl.repeat();
    });
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
        // ── Dot + pulse ring ───────────────────────────────────────────────
        SizedBox(
          width: 48,
          height: 45,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) => Stack(
              alignment: Alignment.center,
              children: [
                // Pulse ring
                Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _color.withAlpha((_opacity.value * 255).round()),
                    ),
                  ),
                ),
                // Core dot
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _color,
                    boxShadow: [
                      BoxShadow(
                        color: _color.withAlpha(160),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Address label ──────────────────────────────────────────────────
        Container(
          constraints: const BoxConstraints(maxWidth: 110),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(230),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.divider.withAlpha(80),
              width: 0.5,
            ),
          ),
          child: Text(
            '${widget.mission.currency} ${widget.mission.price.toInt()}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// ─── User location dot ────────────────────────────────────────────────────────
class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF00D4CC),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4CC).withAlpha(120),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

// ─── Bottom overlay ───────────────────────────────────────────────────────────

class _BottomOverlay extends StatelessWidget {
  final MapsTabController ctrl;
  const _BottomOverlay({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withAlpha(0),
            AppColors.background.withAlpha(220),
            AppColors.background,
          ],
          stops: const [0.0, 0.3, 0.6],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'See anywhere.\nKnow everything.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Obx(() {
            final count = ctrl.activeMissions.length;
            return Text(
              count == 0
                  ? 'Tap map · Long-press to post a mission'
                  : '$count active mission${count == 1 ? '' : 's'} on the map',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            );
          }),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Get.toNamed(PostMissionPage.route),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
              ),
              child: const Text(
                '+ Post a Mission',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grid background painter ──────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withAlpha(20)
      ..strokeWidth = 0.5;

    const step = 60.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
