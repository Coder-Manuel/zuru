import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/missions/presentation/controllers/radar_controller.dart';
import 'package:zuru/modules/missions/presentation/pages/mission_details_page.dart';
import 'package:zuru/modules/missions/presentation/widgets/mission_card.dart';

/// Opens the "All Missions" bottom sheet — a scrollable list of every nearby
/// mission. The radar panel only previews the top few; this shows them all.
Future<void> showAllMissionsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: ScoutColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _AllMissionsSheet(),
  );
}

class _AllMissionsSheet extends GetView<RadarController> {
  const _AllMissionsSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Column(
          children: [
            // ── Grab handle ───────────────────────────────────────────────
            12.verticalSpace,
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ScoutColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Header ────────────────────────────────────────────────────
            GetBuilder<RadarController>(
              id: controller.missionsBuilder,
              builder: (_) {
                final count = controller.missions.length;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          count == 0
                              ? 'NO ACTIVE LIVE CHECKS NEARBY'
                              : '$count ACTIVE LIVE CHECK${count == 1 ? '' : 'S'} NEARBY',
                          style: TextStyle(
                            color: ScoutColors.textAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: Get.back,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: ScoutColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: ScoutColors.textSecondary,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── List ──────────────────────────────────────────────────────
            Expanded(
              child: GetBuilder<RadarController>(
                id: controller.missionsBuilder,
                builder: (_) {
                  final missions = controller.missions;
                  if (missions.isEmpty) {
                    return Center(
                      child: Text(
                        'No live checks nearby',
                        style: TextStyle(
                          color: ScoutColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: missions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final mission = missions[i];
                      return MissionCard(
                        mission: mission,
                        onTap: () {
                          // Close the sheet first, then open details.
                          Get.back();
                          Get.toNamed(
                            MissionDetailsPage.route,
                            arguments: mission,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
