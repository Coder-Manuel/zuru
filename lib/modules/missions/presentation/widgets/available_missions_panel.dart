import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/utils/extensions.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/core/widgets/location_listener.builder.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/presentation/controllers/radar_controller.dart';
import 'package:zuru/modules/missions/presentation/pages/mission_details_page.dart';

class MissionsPanel extends GetView<RadarController> {
  const MissionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ScoutColors.background,
      child: GetBuilder<RadarController>(
        id: controller.missionsBuilder,
        builder: (_) {
          final all = controller.missions;
          // Show at most 4 missions in the bottom list per design
          final preview = all.take(4).toList();
          final count = all.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 5, 20, 12),
                child: Text(
                  count == 0
                      ? 'NO ACTIVE MISSIONS NEARBY'
                      : '$count ACTIVE MISSION${count == 1 ? '' : 'S'} NEARBY',
                  style: TextStyle(
                    color: ScoutColors.textAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // List or empty placeholder
              Obx(() {
                return Expanded(
                  child: controller.isLoading.value
                      ? const _LoadingShimmer()
                      : preview.isEmpty
                      ? const _NoMissionsPlaceholder()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: preview.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _MissionCard(mission: preview[i]),
                        ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

// ── No missions placeholder ───────────────────────────────────────────────────
class _NoMissionsPlaceholder extends StatelessWidget {
  const _NoMissionsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ScoutColors.surface,
            ),
            child: Icon(
              Icons.radar_outlined,
              color: ScoutColors.textSecondary,
              size: 28,
            ),
          ),
          16.verticalSpace,
          Text(
            'No missions nearby',
            style: TextStyle(
              color: ScoutColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          8.verticalSpace,
          Text(
            'New missions will appear here\nas they become available.',
            style: TextStyle(
              color: ScoutColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Loading shimmer ───────────────────────────────────────────────────────────
class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        height: 72,
        decoration: BoxDecoration(
          color: ScoutColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

// ── Mission card ──────────────────────────────────────────────────────────────
class _MissionCard extends StatelessWidget {
  final MissionEntity mission;

  const _MissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(MissionDetailsPage.route, arguments: mission),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: ScoutColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${mission.type?.label} \n${mission.address}',
                    style: TextStyle(
                      color: ScoutColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  6.verticalSpace,
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 15,
                            color: ScoutColors.primary,
                          ),
                          5.horizontalSpace,
                          Text(
                            '${((mission.durationInSec / 60).round())}min',
                            style: TextStyle(
                              color: ScoutColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      10.horizontalSpace,
                      LocationListenerBuilder(
                        latitude: mission.latitude ?? 0.0,
                        longitude: mission.longitude ?? 0.0,
                        builder: (_, distance) {
                          return Text(
                            '${distance?.formatDistance} away',
                            style: TextStyle(
                              color: ScoutColors.textSecondary,
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            16.horizontalSpace,
            Text(
              mission.formattedPrice,
              style: TextStyle(
                color: ScoutColors.textAccent,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
