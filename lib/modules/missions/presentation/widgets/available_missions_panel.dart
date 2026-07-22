import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
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
                child: Obx(
                  () => Text(
                    controller.hasLocationError
                        ? 'LOCATION UNAVAILABLE'
                        : controller.showLoading
                        ? (controller.isResolvingLocation
                              // The centred loader below owns this message.
                              ? ''
                              : 'SCANNING FOR LIVE CHECKS…')
                        : count == 0
                        ? 'NO ACTIVE LIVE CHECKS NEARBY'
                        : '$count ACTIVE LIVE CHECK${count == 1 ? '' : 'S'} NEARBY',
                    style: TextStyle(
                      color: controller.hasLocationError
                          ? ScoutColors.scoutMarker
                          : ScoutColors.textAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              // List, location error, loading, or empty placeholder
              Obx(() {
                // Append a trailing "See All" row when there are more missions
                // than the preview shows.
                final hasMore = count > preview.length;
                final itemCount = preview.length + (hasMore ? 1 : 0);

                // While location is still resolving (or the nearby stream is
                // loading) show a shimmer — not the empty/error state. This
                // covers both the initial load and tapping "Try again".
                // Location acquisition gets its own dedicated loader so the
                // scout knows *why* they're waiting.
                if (controller.showLoading) {
                  return Expanded(
                    child: controller.isResolvingLocation
                        ? const _LocatingLoader()
                        : const _LoadingShimmer(),
                  );
                }

                // A location failure blocks the nearby-missions stream entirely,
                // so surface it (with a call to action) instead of a misleading
                // "no missions" empty state.
                if (controller.hasLocationError) {
                  return const Expanded(child: _LocationErrorPlaceholder());
                }

                return Expanded(
                  child: preview.isEmpty
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
              'See all $count live checks',
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
            'No live checks nearby',
            style: TextStyle(
              color: ScoutColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          8.verticalSpace,
          Text(
            'New live checks will appear here\nas they become available.',
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

// ── Location error placeholder ────────────────────────────────────────────────
class _LocationErrorPlaceholder extends GetView<RadarController> {
  const _LocationErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Obx(() {
          final message =
              controller.locationError.value ??
              'We can\'t access your location right now.';

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ScoutColors.scoutMarker.withAlpha(30),
                ),
                child: Icon(
                  Icons.location_off_rounded,
                  color: ScoutColors.scoutMarker,
                  size: 28,
                ),
              ),
              16.verticalSpace,
              Text(
                'Location needed to find live checks',
                style: TextStyle(
                  color: ScoutColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              8.verticalSpace,
              Text(
                message,
                style: TextStyle(
                  color: ScoutColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              20.verticalSpace,

              // Primary action — retry the location bootstrap.
              _ActionButton(
                label: 'Try again',
                filled: true,
                onTap: controller.retryLocation,
              ),

              // Secondary action — jump straight to the relevant settings when
              // a retry alone can't fix it.
              if (controller.isLocationServiceDisabled) ...[
                10.verticalSpace,
                _ActionButton(
                  label: 'Open location settings',
                  filled: false,
                  onTap: controller.openLocationSettings,
                ),
              ] else if (controller.isLocationPermanentlyDenied) ...[
                10.verticalSpace,
                _ActionButton(
                  label: 'Open app settings',
                  filled: false,
                  onTap: controller.openAppSettings,
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? ScoutColors.primary : ScoutColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: filled
              ? null
              : Border.all(color: ScoutColors.primary.withAlpha(60)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: filled ? Colors.black : ScoutColors.textAccent,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ── Locating loader ───────────────────────────────────────────────────────────
// Distinct from the mission-card shimmer: a centred, shimmering location pin +
// "Getting your location…" label shown while GPS is being acquired, so the
// scout knows what they're waiting on.
class _LocatingLoader extends StatelessWidget {
  const _LocatingLoader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Shimmer.fromColors(
        baseColor: ScoutColors.textSecondary,
        highlightColor: ScoutColors.primary,
        period: const Duration(milliseconds: 1500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.my_location_rounded,
              size: 46,
              color: Colors.white,
            ),
            16.verticalSpace,
            const Text(
              'Getting your location…',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            14.verticalSpace,
            // Skeleton bars reinforce the "loading" feel.
            _LocatingBar(width: 160),
            8.verticalSpace,
            _LocatingBar(width: 110),
          ],
        ),
      ),
    );
  }
}

class _LocatingBar extends StatelessWidget {
  final double width;
  const _LocatingBar({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
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
