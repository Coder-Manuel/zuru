import 'package:flutter/material.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/utils/size.util.dart';

class ScoutFeedCard extends StatelessWidget {
  final User scout;
  final VoidCallback onTap;

  const ScoutFeedCard({super.key, required this.scout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final profile = scout.scoutProfile;
    final name = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName
        : 'Scout';
    final tags = (profile?.tags ?? const []).take(3).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ClientColors.inputBg.withAlpha(120),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ClientColors.divider.withAlpha(120)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FeedAvatar(
                  name: name,
                  avatarUrl: profile?.avatarUrl,
                  availability: profile?.availability,
                ),
                14.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: ClientColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      if (profile?.locality != null &&
                          profile!.locality!.isNotEmpty) ...[
                        4.verticalSpace,
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: ClientColors.primary,
                              size: 14,
                            ),
                            4.horizontalSpace,
                            Flexible(
                              child: Text(
                                profile.locality!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: ClientColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                10.horizontalSpace,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusBadge(availability: profile?.availability),
                    10.verticalSpace,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          profile?.rating?.toStringAsFixed(1) ?? '–',
                          style: const TextStyle(
                            color: ClientColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        4.horizontalSpace,
                        const Icon(
                          Icons.star_rounded,
                          color: ClientColors.primary,
                          size: 16,
                        ),
                      ],
                    ),
                    2.verticalSpace,
                    Text(
                      '${profile?.totalReviews ?? 0} missions',
                      style: const TextStyle(
                        color: ClientColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (tags.isNotEmpty) ...[
              14.verticalSpace,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((t) => _TagPill(label: t)).toList(),
              ),
            ],

            if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
              14.verticalSpace,
              Text(
                profile.bio!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ClientColors.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],

            16.verticalSpace,
            Divider(color: ClientColors.divider.withAlpha(120), height: 1),
            14.verticalSpace,
            Row(
              children: [
                const Text(
                  'Tap to view profile',
                  style: TextStyle(
                    color: ClientColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                6.horizontalSpace,
                const Icon(
                  Icons.chevron_right_rounded,
                  color: ClientColors.primary,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar with status dot ───────────────────────────────────────────────────

class _FeedAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final ScoutAvailability? availability;

  const _FeedAvatar({
    required this.name,
    required this.availability,
    this.avatarUrl,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ClientColors.inputBg,
              border: Border.all(
                color: ClientColors.primary.withAlpha(160),
                width: 1.5,
              ),
            ),
            child: Center(
              child: avatarUrl != null
                  ? SizedBox(
                      width: 60,
                      height: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.network(avatarUrl!, fit: BoxFit.cover),
                      ),
                    )
                  : Text(
                      _initials,
                      style: const TextStyle(
                        color: ClientColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          if (availability != null && availability != ScoutAvailability.offline)
            Positioned(
              right: 0,
              bottom: 2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: ClientColors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: ClientColors.background, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Status badge (driven by the scout's availability status) ─────────────────

class _StatusBadge extends StatelessWidget {
  final ScoutAvailability? availability;

  const _StatusBadge({required this.availability});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    final bool dot;

    switch (availability) {
      case ScoutAvailability.available:
        label = 'AVAILABLE';
        color = ClientColors.green;
        dot = true;
      case ScoutAvailability.bookable:
        label = 'BOOKABLE';
        color = ClientColors.primary;
        dot = false;
      case ScoutAvailability.offline:
        label = 'OFFLINE';
        color = ClientColors.textSecondary;
        dot = false;
      case null:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            6.horizontalSpace,
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category chip with amber border ──────────────────────────────────────────

class _TagPill extends StatelessWidget {
  final String label;
  const _TagPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClientColors.primary.withAlpha(150)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: ClientColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
