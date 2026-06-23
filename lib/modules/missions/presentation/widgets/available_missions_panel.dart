import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/missions/presentation/controllers/radar_controller.dart';
import 'package:zuru/modules/missions/presentation/widgets/all_missions_sheet.dart';
import 'package:zuru/modules/missions/presentation/widgets/mission_card.dart';

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
          // Show at most 3 missions in the bottom list per design
          final preview = all.take(3).toList();
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
                // Append a trailing "See All" row when there are more missions
                // than the preview shows.
                final hasMore = count > preview.length;
                final itemCount = preview.length + (hasMore ? 1 : 0);

                return Expanded(
                  child: controller.isLoading.value
                      ? const _LoadingShimmer()
                      : preview.isEmpty
                      ? const _NoMissionsPlaceholder()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: itemCount,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            if (hasMore && i == preview.length) {
                              return _SeeAllButton(
                                count: count,
                                onTap: () => showAllMissionsSheet(context),
                              );
                            }
                            return MissionCard(mission: preview[i]);
                          },
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

// ── "See all" button ──────────────────────────────────────────────────────────
class _SeeAllButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _SeeAllButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: ScoutColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ScoutColors.primary.withAlpha(60)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'See all $count missions',
              style: TextStyle(
                color: ScoutColors.textAccent,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            6.horizontalSpace,
            Icon(
              Icons.arrow_forward_rounded,
              color: ScoutColors.textAccent,
              size: 18,
            ),
          ],
        ),
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
