import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/services/location_service/location_service.dart';
import 'package:zuru/core/utils/extensions.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/core/widgets/location_listener.builder.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/presentation/controllers/radar_controller.dart';
import 'package:zuru/modules/missions/presentation/pages/mission_details_page.dart';
import 'package:zuru/modules/missions/presentation/widgets/mission_marker_widget.dart';
import 'package:zuru/modules/missions/presentation/widgets/radar_grid_painter.dart';
import 'package:zuru/modules/missions/presentation/widgets/radar_sweep_painter.dart';

class RadarMap extends GetView<RadarController> {
  final double mapHeight;

  // Location service is global — read it directly here so the map can show
  // permission errors / retry without coupling RadarController to location.
  final _location = Get.find<LocationService>();

  RadarMap({super.key, required this.mapHeight});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final size = Get.mediaQuery.size;

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Grid
            Positioned.fill(
              child: CustomPaint(painter: const RadarGridPainter()),
            ),

            // Rotating sweep
            Positioned.fill(
              child: AnimatedBuilder(
                animation: controller.sweepController,
                builder: (_, _) {
                  final rotation =
                      controller.sweepController.value * 2 * pi - pi / 2;
                  return CustomPaint(
                    painter: RadarSweepPainter(rotation: rotation),
                  );
                },
              ),
            ),

            // Mission markers — hidden when a mission is active
            GetBuilder<RadarController>(
              id: controller.missionsBuilder,
              builder: (_) {
                if (controller.missions.isEmpty) return const SizedBox.shrink();

                // ── Anchor: user's GPS when available, else mission centroid ──
                final userLat = _location.latitude;
                final userLng = _location.longitude;
                final (clat, clng) = (userLat != null && userLng != null)
                    ? (userLat, userLng)
                    : _centroid(controller.missions);

                // Screen centre == "YOU ARE HERE" badge position.
                final cx = size.width * 0.50;
                final cy = mapHeight * 0.50;

                // Usable radar radius in pixels — shrunk by an inset so the
                // farthest markers don't press against the widget edge.
                const edgeInset = 5.0;
                final usableRadius =
                    min(size.width / 2, mapHeight / 2) - edgeInset;

                // MissionMarkerWidget geometry:
                //   dot SizedBox: 52 × 52  → dot centre at (26, 26)
                //   gap:           4 px
                //   price pill:   ≈ 28 px tall, up to ~100 px wide
                const dotR = 20.0; // half of 52-px SizedBox
                const labelH = 15.0; // approximate price-pill height incl. gap
                const halfW = 55.0; // half of max expected marker width

                // YOU badge dot is ≈ centred at cx; badge extends ~35 px
                // to the right.  50 px gives comfortable clearance without
                // wasting too much of the inner ring.
                const minRadiusPx = 50.0;

                return Stack(
                  children: [
                    for (int i = 0; i < controller.missions.length; i++)
                      Builder(
                        builder: (_) {
                          final m = controller.missions[i];

                          // ── Step 1: compute actual km distance & bearing ──
                          // Use flat-earth km conversion; cos(lat) corrects for
                          // longitude compression away from the equator.
                          const kmPerDeg = 500;
                          final mLat = m.latitude ?? 0.0;
                          final mLng = m.longitude ?? 0.0;
                          final dxKm =
                              (mLng - clng) * kmPerDeg * cos(clat * pi / 180);
                          final dyKm = (mLat - clat) * kmPerDeg;
                          final distKm = sqrt(dxKm * dxKm + dyKm * dyKm);

                          // Screen bearing: east = +x, north = -y (screen y
                          // increases downward, so negate the latitude offset).
                          final bearing = atan2(-dyKm, dxKm);

                          // ── Step 2: logarithmic compression ─────────────
                          // Linear scale bunches every nearby mission inside
                          // the clearance ring.  log(1 + d) / log(1 + max)
                          // spreads short distances apart while 400 km still
                          // reaches the edge.
                          //
                          //   4 km  → 26 % of usableRadius
                          //  50 km  → 65 % of usableRadius
                          // 137 km  → 82 % of usableRadius
                          // 400 km  → 100 % of usableRadius
                          const maxRangeKm = 500.0;
                          final logDist =
                              log(1 + distKm.clamp(1, maxRangeKm)) /
                              log(1 + maxRangeKm);
                          final pixelDist = logDist * usableRadius;

                          // ── Step 3: back to screen coordinates ───────────
                          final rawX = cx + cos(bearing) * pixelDist;
                          final rawY = cy + sin(bearing) * pixelDist;

                          // ── Step 4: push clear of the YOU badge ──────────
                          final dx = rawX - cx;
                          final dy = rawY - cy;
                          final distFromCentre = sqrt(dx * dx + dy * dy);
                          final double adjX;
                          final double adjY;
                          if (distFromCentre < minRadiusPx &&
                              distFromCentre > 0.001) {
                            adjX = cx + cos(bearing) * minRadiusPx;
                            adjY = cy + sin(bearing) * minRadiusPx;
                          } else {
                            adjX = rawX;
                            adjY = rawY;
                          }

                          // ── Step 5: clamp to radar bounds ────────────────
                          final px = adjX.clamp(halfW, size.width - halfW);
                          final py = adjY.clamp(
                            dotR + 4,
                            mapHeight - dotR - labelH,
                          );

                          return Positioned(
                            left: px - dotR,
                            top: py - dotR,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Get.toNamed(
                                MissionDetailsPage.route,
                                arguments: m,
                              ),
                              child: MissionMarkerWidget(
                                price: m.formattedPrice,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),

            // "YOU ARE HERE" badge
            Positioned(
              left: size.width * 0.50 - 7,
              top: mapHeight * 0.50 - 7,
              child: _YouAreHereBadge(),
            ),
            // Positioned(left: 18, top: 10, child: _YouAreHereBadge()),

            // Locked overlay — shown while a mission is in progress
            Obx(() {
              if (!controller.hasActiveMission) return const SizedBox.shrink();
              return Positioned.fill(
                child: _LockedRadarOverlay(
                  mission: controller.activeMission.value,
                ),
              );
            }),

            // Loading overlay — shown while acquiring the first fix
            Obx(() {
              if (!controller.isLoading.value) return const SizedBox.shrink();
              return Positioned.fill(
                child: Container(
                  color: ScoutColors.background.withAlpha(160),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: ScoutColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              );
            }),

            // Location error overlay — driven by the global LocationService
            Obx(() {
              final err = _location.error.value;
              if (err == null) return const SizedBox.shrink();
              return Positioned.fill(
                child: Container(
                  color: ScoutColors.background.withAlpha(200),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off_outlined,
                        color: ScoutColors.textSecondary,
                        size: 36,
                      ),
                      12.verticalSpace,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          err,
                          style: TextStyle(
                            color: ScoutColors.textSecondary,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      16.verticalSpace,
                      TextButton(
                        onPressed: _location.retryInit,
                        child: Text(
                          'Retry',
                          style: TextStyle(color: ScoutColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static (double, double) _centroid(List<MissionEntity> missions) {
    final lat =
        missions.map((m) => m.latitude ?? 0.0).reduce((a, b) => a + b) /
        missions.length;
    final lng =
        missions.map((m) => m.longitude ?? 0.0).reduce((a, b) => a + b) /
        missions.length;
    return (lat, lng);
  }
}

// ── Locked radar overlay ──────────────────────────────────────────────────────

class _LockedRadarOverlay extends StatelessWidget {
  final MissionEntity? mission;
  const _LockedRadarOverlay({this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ScoutColors.background.withAlpha(180),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ScoutColors.scoutMarker.withAlpha(25),
              border: Border.all(
                color: ScoutColors.scoutMarker.withAlpha(100),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: ScoutColors.scoutMarker,
              size: 26,
            ),
          ),
          14.verticalSpace,
          Text(
            'RADAR LOCKED',
            style: TextStyle(
              color: ScoutColors.scoutMarker,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          8.verticalSpace,
          LocationListenerBuilder(
            latitude: mission!.latitude ?? 0.0,
            longitude: mission!.longitude ?? 0.0,
            builder: (_, distance) {
              return Text(
                mission != null
                    ? 'Mission in progress · ${distance?.formatDistance} away'
                    : 'Complete your current mission\nto scan for new ones.',
                style: TextStyle(
                  color: ScoutColors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── "YOU ARE HERE" badge ───────────────────────────────────────────────────────
class _YouAreHereBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: ScoutColors.surface.withAlpha(220),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ScoutColors.primary.withAlpha(60), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ScoutColors.scoutMarker,
              boxShadow: [
                BoxShadow(
                  color: ScoutColors.primary.withAlpha(120),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          8.horizontalSpace,
          Text(
            'YOU',
            style: TextStyle(
              color: ScoutColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
