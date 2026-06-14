import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/core/entities/profile.entity.dart';
import 'package:zuru/core/entities/profile_clip.entity.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/core/widgets/reels_player_page.dart';
import 'package:zuru/core/widgets/video_thumbnail_view.dart';
import 'package:zuru/modules/scouts/presentation/controllers/scout_detail_controller.dart';
import 'package:zuru/modules/scouts/presentation/widgets/animated_avatar_ring.dart';
import 'package:zuru/modules/scouts/presentation/widgets/scout_detail_skeleton.dart';

class ScoutDetailPage extends GetView<ScoutDetailController> {
  static const String route = '/scouts/detail';

  const ScoutDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.background,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const ScoutDetailSkeleton();
          }
          final profile = controller.scout.value?.scoutProfile;
          if (profile == null) {
            return _DetailError(
              message: controller.error.value ?? 'Scout not found',
            );
          }
          return _DetailBody(
            profile: profile,
            onRequestLive: controller.requestLive,
          );
        }),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final Profile profile;
  final VoidCallback onRequestLive;

  const _DetailBody({required this.profile, required this.onRequestLive});

  @override
  Widget build(BuildContext context) {
    // Staggered slide-in for each block.
    var step = 0;
    Widget animate(Widget child) {
      final delay = (step++ * 80).ms;
      return child
          .animate()
          .fadeIn(delay: delay, duration: 450.ms)
          .slideY(begin: 0.12, end: 0, delay: delay, duration: 450.ms);
    }

    final meta = _metaLine(profile);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          animate(const _TopBar()),
          4.verticalSpace,
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  10.verticalSpace,
                  animate(
                    AnimatedAvatarRing(
                      initials: _initials(profile.fullName),
                      imageUrl: profile.avatarUrl,
                      size: 150,
                    ),
                  ),
                  12.verticalSpace,
                  animate(
                    Text(
                      profile.fullName.isNotEmpty ? profile.fullName : 'Scout',
                      style: const TextStyle(
                        color: ClientColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (profile.locality != null &&
                      profile.locality!.isNotEmpty) ...[
                    8.verticalSpace,
                    animate(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: ClientColors.primary,
                            size: 16,
                          ),
                          4.horizontalSpace,
                          Text(
                            profile.locality!,
                            style: const TextStyle(
                              color: ClientColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  18.verticalSpace,
                  animate(_PillsRow(profile: profile)),
                  if (meta != null) ...[
                    16.verticalSpace,
                    animate(
                      Text(
                        meta,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: ClientColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],

                  if (profile.clips.isNotEmpty) ...[
                    28.verticalSpace,
                    animate(
                      _SectionLabel(
                        'PROFILE CATALOGUE · ${profile.clips.length} CLIPS',
                      ),
                    ),
                    14.verticalSpace,
                    animate(_ClipsCatalogue(clips: profile.clips)),
                  ],

                  if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                    24.verticalSpace,
                    animate(_BioQuote(bio: profile.bio!)),
                  ],

                  24.verticalSpace,
                  animate(_StatsCard(profile: profile)),

                  if (profile.tags.isNotEmpty) ...[
                    28.verticalSpace,
                    animate(const _SectionLabel('MISSION ZONES')),
                    14.verticalSpace,
                    animate(_MissionZones(zones: profile.tags)),
                  ],
                  16.verticalSpace,

                  // Request a Live — last item in the page (not floating).
                  _RequestLiveFooter(
                    profile: profile,
                    onTap: onRequestLive,
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: Get.back,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ClientColors.inputBg.withAlpha(150),
              shape: BoxShape.circle,
              border: Border.all(color: ClientColors.divider),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: ClientColors.textPrimary,
              size: 18,
            ),
          ),
        ),
        16.horizontalSpace,
        const Text(
          'SCOUT PROFILE',
          style: TextStyle(
            color: ClientColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// ── Pills row ────────────────────────────────────────────────────────────────

class _PillsRow extends StatelessWidget {
  final Profile profile;
  const _PillsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    final availability = profile.availability ?? ScoutAvailability.offline;
    final availColor = switch (availability) {
      ScoutAvailability.available => ClientColors.green,
      ScoutAvailability.bookable => ClientColors.primary,
      ScoutAvailability.offline => ClientColors.textSecondary,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Pill(
          label: availability.label.toUpperCase(),
          color: availColor,
          showDot: availability == ScoutAvailability.available,
        ),
        10.horizontalSpace,
        _Pill(
          label: '${profile.totalReviews ?? 0} MISSIONS',
          color: ClientColors.primary,
        ),
        10.horizontalSpace,
        _Pill(
          label: profile.rating?.toStringAsFixed(1) ?? '–',
          color: ClientColors.textPrimary,
          trailingStar: true,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final bool showDot;
  final bool trailingStar;

  const _Pill({
    required this.label,
    required this.color,
    this.showDot = false,
    this.trailingStar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
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
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (trailingStar) ...[
            4.horizontalSpace,
            Icon(Icons.star_rounded, color: color, size: 15),
          ],
        ],
      ),
    );
  }
}

// ── Clips catalogue ──────────────────────────────────────────────────────────

class _ClipsCatalogue extends StatelessWidget {
  final List<ProfileClip> clips;
  const _ClipsCatalogue({required this.clips});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(clips.length, (i) {
        final isLast = i == clips.length - 1;
        final clip = clips[i];
        final label = (clip.title?.isNotEmpty ?? false)
            ? clip.title!.toUpperCase()
            : 'CLIP ${i + 1}';
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 12),
            child: SizedBox(
              height: 100,
              child: _ClipTile(
                mediaUrl: clip.mediaUrl,
                label: label,
                onTap: () => _play(i),
              ),
            ),
          ),
        );
      }),
    );
  }

  void _play(int index) {
    final urls = clips
        .map((c) => c.mediaUrl)
        .whereType<String>()
        .where((u) => u.isNotEmpty)
        .toList();
    if (urls.isEmpty) return;
    final titles = clips
        .map((c) => (c.title?.isNotEmpty ?? false) ? c.title! : 'Clip')
        .toList();
    ReelsPlayerPage.open(urls, initialIndex: index, titles: titles);
  }
}

class _ClipTile extends StatelessWidget {
  final String? mediaUrl;
  final String label;
  final VoidCallback onTap;

  const _ClipTile({
    required this.mediaUrl,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final url = mediaUrl;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: (url != null && url.isNotEmpty)
                ? VideoThumbnailView(
                    url: url,
                    borderRadius: BorderRadius.circular(14),
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      color: ClientColors.inputBg.withAlpha(120),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ClientColors.divider.withAlpha(120),
                      ),
                    ),
                  ),
          ),
          Positioned(
            left: 10,
            bottom: 8,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bio quote ────────────────────────────────────────────────────────────────

class _BioQuote extends StatelessWidget {
  final String bio;
  const _BioQuote({required this.bio});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ClientColors.inputBg.withAlpha(120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.divider.withAlpha(120)),
      ),
      child: Text(
        '“$bio”',
        style: const TextStyle(
          color: ClientColors.textPrimary,
          fontSize: 15,
          height: 1.5,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Stats card ───────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final Profile profile;
  const _StatsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final rating = profile.rating ?? 0;
    final fulfillment = profile.fulfillmentRate;
    final response = profile.avgResponseMinutes;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClientColors.inputBg.withAlpha(120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.divider.withAlpha(120)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Big rating
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: ClientColors.primary,
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  8.verticalSpace,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < rating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: ClientColors.primary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            VerticalDivider(
              color: ClientColors.divider.withAlpha(120),
              width: 32,
            ),
            // Bars
            Expanded(
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatBar(
                    label: 'FULFILLMENT',
                    value: fulfillment != null
                        ? '${(fulfillment * 100).round()}%'
                        : '—',
                    fraction: fulfillment ?? 0,
                  ),
                  16.verticalSpace,
                  // Rating breakdown uses the actual rating value (no breakdown
                  // data tracked yet).
                  _StatBar(
                    label: 'RATINGS',
                    value: rating.toStringAsFixed(1),
                    fraction: (rating / 5).clamp(0, 1).toDouble(),
                    trailingStar: true,
                  ),
                  16.verticalSpace,
                  _StatBar(
                    label: 'RESPONSE',
                    value: response != null
                        ? '${response.toStringAsFixed(response % 1 == 0 ? 0 : 1)} MIN'
                        : '—',
                    // Lower response time → fuller bar.
                    fraction: response != null
                        ? (1 - (response / 15).clamp(0, 1)).toDouble()
                        : 0,
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

class _StatBar extends StatelessWidget {
  final String label;
  final String value;
  final double fraction;
  final bool trailingStar;

  const _StatBar({
    required this.label,
    required this.value,
    required this.fraction,
    this.trailingStar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: ClientColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: ClientColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (trailingStar) ...[
                  3.horizontalSpace,
                  const Icon(
                    Icons.star_rounded,
                    color: ClientColors.textPrimary,
                    size: 13,
                  ),
                ],
              ],
            ),
          ],
        ),
        8.verticalSpace,
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: ClientColors.divider.withAlpha(120),
            valueColor: const AlwaysStoppedAnimation(ClientColors.primary),
          ),
        ),
      ],
    );
  }
}

// ── Mission zones ────────────────────────────────────────────────────────────

class _MissionZones extends StatelessWidget {
  final List<String> zones;
  const _MissionZones({required this.zones});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: zones
          .map(
            (z) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: ClientColors.primary.withAlpha(150)),
              ),
              child: Text(
                z.toUpperCase(),
                style: const TextStyle(
                  color: ClientColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Request a Live footer ────────────────────────────────────────────────────

class _RequestLiveFooter extends StatelessWidget {
  final Profile profile;
  final VoidCallback onTap;

  const _RequestLiveFooter({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(color: ClientColors.background),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: ClientColors.primary,
                foregroundColor: ClientColors.background,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Request a Live',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          12.verticalSpace,
          Text(
            _footerText(profile),
            style: const TextStyle(
              color: ClientColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: ClientColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  final String message;
  const _DetailError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: _TopBar(),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ClientColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}

String? _metaLine(Profile profile) {
  final parts = <String>[];
  if (profile.avgResponseMinutes != null) {
    parts.add('Responds ~${profile.avgResponseMinutes!.round()} min');
  }
  if (profile.languages.isNotEmpty) {
    parts.add('Speaks ${profile.languages.join(' · ')}');
  }
  return parts.isEmpty ? null : parts.join(' · ');
}

String _footerText(Profile profile) {
  final pricing = profile.sessionPricing;
  if (pricing.isEmpty) return 'Payment held in escrow · GPS verified';
  final min = pricing.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  final currency = pricing.first.currency;
  return 'From $currency $min · Payment held in escrow · GPS verified';
}
