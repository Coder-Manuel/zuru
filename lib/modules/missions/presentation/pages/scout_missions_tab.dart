import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/utils/extensions.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/presentation/controllers/missions_controller.dart';
import 'package:zuru/modules/rating/presentation/pages/rate_client_page.dart';

class ScoutMissionsTab extends GetView<MissionsController> {
  const ScoutMissionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: controller.fetchMissions(),
          builder: (_, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Missions',
                        style: TextStyle(
                          color: ScoutColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Filter row ────────────────────────────────────────────────
                Obx(
                  () => _FilterRow(
                    activeFilter: controller.activeFilter.value,
                    onFilterChanged: controller.setFilter,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Body ──────────────────────────────────────────────────────
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const _ShimmerList();
                    }

                    final missions = controller.filteredMissions;

                    if (missions.isEmpty) {
                      return _EmptyState(filter: controller.activeFilter.value);
                    }

                    return RefreshIndicator(
                      color: ScoutColors.primary,
                      backgroundColor: ScoutColors.surface,
                      onRefresh: controller.fetchMissions,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                        itemCount: missions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (_, i) => _MissionCard(
                          mission: missions[i],
                          onComplete: () =>
                              controller.onTapMission(missions[i]),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Filter row ───────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final MissionFilter activeFilter;
  final void Function(MissionFilter) onFilterChanged;

  const _FilterRow({required this.activeFilter, required this.onFilterChanged});

  static const _labels = {
    MissionFilter.all: 'All',
    MissionFilter.active: 'Active',
    MissionFilter.accepted: 'Accepted',
    MissionFilter.completed: 'Completed',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: MissionFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final filter = MissionFilter.values[i];
          final selected = filter == activeFilter;
          return GestureDetector(
            onTap: () => onFilterChanged(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? ScoutColors.primary : ScoutColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _labels[filter]!,
                style: TextStyle(
                  color: selected ? Colors.black : ScoutColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Mission card ─────────────────────────────────────────────────────────────

class _MissionCard extends StatelessWidget {
  final MissionEntity mission;
  final VoidCallback? onComplete;

  const _MissionCard({required this.mission, this.onComplete});

  @override
  Widget build(BuildContext context) {
    final createdAt = mission.createdAt != null
        ? DateTime.tryParse(mission.createdAt!)
        : null;

    return GestureDetector(
      onTap: () {
        if (mission.status == MissionStatus.completed && !mission.hasRated) {
          Get.toNamed(RateClientPage.route, arguments: mission);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ScoutColors.surface.setOpacity(0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ScoutColors.divider.withAlpha(40),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address as mission "title"
                Expanded(
                  child: Text(
                    '${mission.type?.label}\n${mission.address}',
                    style: TextStyle(
                      color: ScoutColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: mission.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              mission.description,
              style: TextStyle(
                color: ScoutColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Duration
                Icon(
                      Icons.timer_outlined,
                      color: ScoutColors.scoutMarker,
                      size: 14,
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(
                      begin: 0.9,
                      end: 1.0,
                      duration: 800.ms,
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(width: 4),
                Text(
                  mission.durationLabel,
                  style: TextStyle(
                    color: ScoutColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 14),

                // Price
                Text(
                  '${mission.currency} ${mission.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: ScoutColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Time ago
                Icon(
                  Icons.access_time,
                  color: ScoutColors.scoutMarker,
                  size: 13,
                ),
                const SizedBox(width: 3),
                Text(
                  createdAt.timeAgo,
                  style: TextStyle(
                    color: ScoutColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if ([
              MissionStatus.accepted,
              MissionStatus.enroute,
            ].contains(mission.status)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.videocam_rounded, size: 24)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(
                        begin: 0.85,
                        end: 1.0,
                        duration: 900.ms,
                        curve: Curves.easeInOut,
                      ),
                  label: const Text(
                    'Complete Mission',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 30),
                    backgroundColor: ScoutColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final MissionStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MissionStatus.live => ('Live', const Color(0xFF22C55E)),
      MissionStatus.accepted => ('Accepted', ScoutColors.scoutMarker),
      MissionStatus.enroute => (
        'EnRoute',
        const Color.fromARGB(255, 42, 142, 248),
      ),
      MissionStatus.open => ('Pending', ScoutColors.primary),
      MissionStatus.requested => ('Requested', ScoutColors.primary),
      MissionStatus.completed => ('Completed', ScoutColors.textSecondary),
      MissionStatus.cancelled => ('Cancelled', const Color(0xFFEF4444)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Shimmer loading list ─────────────────────────────────────────────────────

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: ScoutColors.surface,
      highlightColor: const Color(0xFF2A3547),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (_, _) => const _ShimmerCard(),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScoutColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ShimmerBox(width: 180, height: 14),
              _ShimmerBox(width: 60, height: 22, radius: 20),
            ],
          ),
          const SizedBox(height: 10),
          // Description lines
          _ShimmerBox(width: double.infinity, height: 12),
          const SizedBox(height: 6),
          _ShimmerBox(width: 220, height: 12),
          const SizedBox(height: 14),
          // Footer row
          Row(
            children: [
              _ShimmerBox(width: 60, height: 12),
              const SizedBox(width: 14),
              _ShimmerBox(width: 50, height: 12),
              const Spacer(),
              _ShimmerBox(width: 55, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final MissionFilter filter;
  const _EmptyState({required this.filter});

  String get _message => switch (filter) {
    MissionFilter.active => 'No live missions right now.',
    MissionFilter.accepted => 'No accepted missions.',
    MissionFilter.completed => 'No completed missions yet.',
    MissionFilter.all => 'You haven\'t accepted any missions yet.',
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ScoutColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.radar_outlined,
                color: ScoutColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ScoutColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
