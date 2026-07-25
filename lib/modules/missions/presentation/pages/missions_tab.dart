import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/core/utils/extensions.dart';
import 'package:zuru/core/widgets/reels_player_page.dart';
import 'package:zuru/core/widgets/video_thumbnail_view.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/presentation/controllers/missions_tab_controller.dart';
import 'package:zuru/modules/missions/presentation/pages/post_mission_page.dart';
import 'package:zuru/modules/rating/presentation/pages/rate_scout_page.dart';

class MissionsTab extends GetView<MissionsTabController> {
  const MissionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Live Checks',
                    style: TextStyle(
                      color: ClientColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.toNamed(PostMissionPage.route),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: ClientColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.black, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'New',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
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
                  color: ClientColors.primary,
                  backgroundColor: ClientColors.surface,
                  onRefresh: controller.fetchMissions,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    itemCount: missions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _MissionCard(
                      mission: missions[i],
                      hasActiveSession: controller.activeSessions.containsKey(
                        missions[i].id,
                      ),
                      onJoinStream: () => controller.onJoinStream(missions[i]),
                    ),
                  ),
                );
              }),
            ),
          ],
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
    MissionFilter.pending: 'Pending',
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
                color: selected ? ClientColors.primary : ClientColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _labels[filter]!,
                style: TextStyle(
                  color: selected ? Colors.black : ClientColors.textSecondary,
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

class _MissionCard extends GetView<MissionsTabController> {
  final MissionEntity mission;
  final bool hasActiveSession;
  final VoidCallback onJoinStream;

  const _MissionCard({
    required this.mission,
    required this.hasActiveSession,
    required this.onJoinStream,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = mission.createdAt != null
        ? DateTime.tryParse(mission.createdAt!)
        : null;

    return GestureDetector(
      onTap: () async {
        if (mission.status == MissionStatus.completed && !mission.hasRated) {
          await Get.toNamed(RateScoutPage.route, arguments: mission);
          controller.fetchMissions();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ClientColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ClientColors.divider.withAlpha(40),
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
                    '${mission.type?.label}\n${mission.address}${mission.status == MissionStatus.requested ? '\n${mission.scout?.displayName ?? '--'}' : ''}'
                        .trim(),
                    style: TextStyle(
                      color: ClientColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (mission.awaitingScoutResponse)
                  const _PendingBadge(
                    label: 'Awaiting guide',
                    icon: Icons.hourglass_top_rounded,
                  )
                else if (mission.isPayable)
                  const _PendingBadge(
                    label: 'Unpaid',
                    icon: Icons.lock_outline_rounded,
                  )
                else
                  _StatusBadge(status: mission.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              mission.description,
              style: TextStyle(
                color: ClientColors.textSecondary,
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
                      color: ClientColors.textSecondary,
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
                    color: ClientColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 14),

                // Price
                Text(
                  '${mission.currency} ${mission.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: ClientColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Time ago
                Icon(
                  Icons.access_time,
                  color: ClientColors.textSecondary,
                  size: 13,
                ),
                const SizedBox(width: 3),
                Text(
                  createdAt.timeAgo,
                  style: TextStyle(
                    color: ClientColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            // Nothing is owed until the guide accepts a live request.
            if (mission.awaitingScoutResponse) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    size: 14,
                    color: ClientColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Waiting for ${mission.scout?.firstName ?? 'your guide'} '
                      'to accept — you’ll pay once they do.',
                      style: TextStyle(
                        color: ClientColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (mission.isPayable) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => controller.payAndPublish(mission),
                  icon: const Icon(Icons.lock_open_rounded, size: 18),
                  label: Text(
                    mission.awaitingClientPayment
                        ? 'Pay ${mission.formattedPrice} to confirm'
                        : 'Pay ${mission.formattedPrice} to publish',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 30),
                    backgroundColor: ClientColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],

            if (mission.isPublished &&
                (hasActiveSession || mission.status == MissionStatus.live)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onJoinStream,
                  icon: const Icon(Icons.videocam_rounded, size: 20)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(
                        begin: 0.85,
                        end: 1.0,
                        duration: 900.ms,
                        curve: Curves.easeInOut,
                      ),
                  label: const Text(
                    'Join Stream',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 30),
                    backgroundColor: Colors.red[800],
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

            // ── Recording of the completed live check ────────────────────
            if (mission.status == MissionStatus.completed &&
                (mission.hasRecording ||
                    mission.recordingProcessing ||
                    mission.recordingUnavailable)) ...[
              const SizedBox(height: 12),
              _RecordingTile(mission: mission),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Recording tile ───────────────────────────────────────────────────────────

/// Shows the recording of a completed live check on the client card:
///  • ready       → tappable thumbnail + play overlay + REC badge + duration
///  • processing  → egress still running, disabled hint
///  • unavailable → session failed, no recording will arrive
class _RecordingTile extends StatelessWidget {
  final MissionEntity mission;
  const _RecordingTile({required this.mission});

  @override
  Widget build(BuildContext context) {
    if (mission.hasRecording) {
      final url = mission.recordingUrl!;
      return GestureDetector(
        onTap: () => ReelsPlayerPage.open(
          [url],
          titles: [
            '${mission.type?.label ?? 'Live Check'} · ${mission.shortAddress}',
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: VideoThumbnailView(
                  url: url,
                  fit: BoxFit.cover,
                  accent: ClientColors.primary,
                ),
              ),
              const Positioned(top: 8, left: 8, child: _RecBadge()),
              if (mission.recordingDurationSec != null)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _DurationPill(seconds: mission.recordingDurationSec!),
                ),
            ],
          ),
        ),
      );
    }

    // Non-playable states.
    final (icon, label) = mission.recordingProcessing
        ? (Icons.hourglass_top_rounded, 'Recording processing…')
        : (Icons.videocam_off_rounded, 'Recording unavailable');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ClientColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ClientColors.divider.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ClientColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: ClientColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecBadge extends StatelessWidget {
  const _RecBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(140),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'REC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationPill extends StatelessWidget {
  final int seconds;
  const _DurationPill({required this.seconds});

  String get _formatted {
    final d = Duration(seconds: seconds);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(140),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _formatted,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────
/// Amber badge for the two pre-payment states: waiting on the guide to accept,
/// and waiting on the client to pay.
class _PendingBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _PendingBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFF5A020);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MissionStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MissionStatus.live => ('Live', const Color(0xFF22C55E)),
      MissionStatus.accepted => ('Accepted', const Color(0xFF3B82F6)),
      MissionStatus.enroute => ('EnRoute', const Color(0xFF3B82F6)),
      MissionStatus.open => ('Pending', ClientColors.primary),
      MissionStatus.requested => ('Requested', ClientColors.primary),
      MissionStatus.completed => ('Completed', ClientColors.textSecondary),
      MissionStatus.cancelled => ('Cancelled', const Color(0xFFEF4444)),
      MissionStatus.declined => ('Declined', const Color(0xFFEF4444)),
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
      baseColor: ClientColors.surface,
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
        color: ClientColors.surface,
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
    MissionFilter.active => 'No active live checks right now.',
    MissionFilter.pending => 'No pending live checks.',
    MissionFilter.completed => 'No completed live checks yet.',
    MissionFilter.all => 'You haven\'t posted any live checks yet.',
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
                color: ClientColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.radar_outlined,
                color: ClientColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ClientColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (filter == MissionFilter.all) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Get.toNamed(PostMissionPage.route),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: ClientColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'Post a Live Check',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
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
