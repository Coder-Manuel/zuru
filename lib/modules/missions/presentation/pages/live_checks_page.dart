import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/missions/presentation/controllers/live_checks_controller.dart';
import 'package:zuru/modules/missions/presentation/widgets/mission_card.dart';
import 'package:zuru/modules/missions/presentation/widgets/mission_sort_widgets.dart';

/// Every live check within range, sorted the scout's way and loaded a page at
/// a time. Opened from the radar panel's "See all".
class LiveChecksPage extends GetView<LiveChecksController> {
  static const String route = '/live-checks';

  const LiveChecksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScoutColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const _BackButton(),
                  16.horizontalSpace,
                  const Expanded(
                    child: Text(
                      'Live Checks',
                      style: TextStyle(
                        color: ScoutColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Obx(
                    () => controller.isLoading.value
                        ? const SizedBox.shrink()
                        : _CountBadge(count: controller.totalCount.value),
                  ),
                ],
              ),
            ),
            16.verticalSpace,

            // ── Sort — stays put while the list scrolls ──────────────────
            Obx(
              () => MissionSortChips(
                value: controller.sort.value,
                onChanged: controller.setSort,
              ),
            ),
            12.verticalSpace,

            // ── List ─────────────────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _LiveChecksList()),
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Obx(
                        () => controller.hasUpdates
                            ? _UpdatesPill(
                                newCount: controller.newCount.value,
                                onTap: controller.reload,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveChecksList extends GetView<LiveChecksController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const _LoadingShimmer();

      final missions = controller.missions;
      final error = controller.error.value;

      if (missions.isEmpty) {
        return RefreshIndicator(
          color: ScoutColors.primary,
          backgroundColor: ScoutColors.surface,
          onRefresh: controller.reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: 360,
                child: _EmptyState(
                  title: error != null
                      ? 'Couldn\'t load live checks'
                      : 'No live checks nearby',
                  message:
                      error ??
                      'New live checks will appear here\nas they become available.',
                ),
              ),
            ],
          ),
        );
      }

      final hasMore = controller.hasMore;
      return NotificationListener<ScrollNotification>(
        // Fetch the next page a little before the end is reached.
        onNotification: (n) {
          if (n.metrics.extentAfter < 400) controller.loadMore();
          return false;
        },
        child: RefreshIndicator(
          color: ScoutColors.primary,
          backgroundColor: ScoutColors.surface,
          onRefresh: controller.reload,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: missions.length + (hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              if (i == missions.length) return const _LoadingMoreRow();
              return MissionCard(mission: missions[i]);
            },
          ),
        ),
      );
    });
  }
}

// ── "N new" pill ──────────────────────────────────────────────────────────────
class _UpdatesPill extends StatelessWidget {
  final int newCount;
  final VoidCallback onTap;

  const _UpdatesPill({required this.newCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = newCount > 0
        ? '$newCount new live check${newCount == 1 ? '' : 's'}'
        : 'Live checks updated';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: ScoutColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: ScoutColors.primary.withAlpha(80), blurRadius: 12),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_upward_rounded,
              size: 16,
              color: Colors.black,
            ),
            6.horizontalSpace,
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ScoutColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: ScoutColors.textAccent,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: ScoutColors.surface,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.chevron_left,
          color: ScoutColors.textPrimary,
          size: 24,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: ScoutColors.surface,
            ),
            child: const Icon(
              Icons.radar_outlined,
              color: ScoutColors.textSecondary,
              size: 28,
            ),
          ),
          16.verticalSpace,
          Text(
            title,
            style: const TextStyle(
              color: ScoutColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          8.verticalSpace,
          Text(
            message,
            style: const TextStyle(
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

class _LoadingMoreRow extends StatelessWidget {
  const _LoadingMoreRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: ScoutColors.primary,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: 6,
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
