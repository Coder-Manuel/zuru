import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/utils/extensions.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/core/widgets/location_listener.builder.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/presentation/controllers/radar_controller.dart';
import 'package:zuru/modules/missions/presentation/pages/navigation_page.dart';

class MissionDetailsPage extends GetView<RadarController> {
  static const String route = '/mission-details';

  const MissionDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mission = Get.arguments as MissionEntity;

    return Scaffold(
      backgroundColor: ScoutColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  _BackButton(),
                  20.horizontalSpace,
                  const Text(
                    'Mission Details',
                    style: TextStyle(
                      color: ScoutColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            24.verticalSpace,

            // ── Scrollable content ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Distance badge
                    LocationListenerBuilder(
                      latitude: mission.latitude ?? 0.0,
                      longitude: mission.longitude ?? 0.0,
                      builder: (_, distance) {
                        return _DistanceBadge(
                          label:
                              '${mission.address}\n${distance?.formatDistance}',
                        );
                      },
                    ),

                    24.verticalSpace,

                    // Detail rows
                    _DetailCard(
                      children: [
                        _DetailRow(
                          label: 'TYPE',
                          value: mission.type?.label ?? mission.address,
                        ),
                        _Divider(),
                        _DetailRow(
                          label: 'PRICE',
                          value: mission.formattedPrice,
                          valueColor: ScoutColors.textAccent,
                        ),
                        _Divider(),
                        _DetailRow(
                          label: 'DURATION',
                          value:
                              '${(mission.durationInSec / 60).round()} minutes',
                        ),
                        _Divider(),
                        _InstructionsRow(text: mission.description),
                        _Divider(),
                        _ClientRow(
                          name: mission.client?.displayName ?? 'Client',
                          rating: mission.client?.rating ?? 0,
                          missions: mission.client?.totalReviews ?? 0,
                        ),
                      ],
                    ),

                    32.verticalSpace,

                    // ── CTAs — differ based on mission status ─────────────
                    if (mission.status == MissionStatus.accepted) ...[
                      // Already accepted → show navigation CTA
                      ElevatedButton.icon(
                        onPressed: () => Get.toNamed(
                          NavigationPage.route,
                          arguments: mission,
                        ),
                        icon: const Icon(Icons.navigation_rounded, size: 20),
                        label: const Text(
                          'Navigate to Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ScoutColors.primary,
                          foregroundColor: ScoutColors.background,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ] else ...[
                      // Open mission → show Accept / Decline
                      Obx(
                        () => ElevatedButton(
                          onPressed: controller.isAccepting.value
                              ? null
                              : () => controller.acceptMission(mission.id!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ScoutColors.primary,
                            foregroundColor: ScoutColors.background,
                            disabledBackgroundColor: ScoutColors.primary
                                .withAlpha(100),
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: controller.isAccepting.value
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: ScoutColors.background,
                                  ),
                                )
                              : const Text(
                                  'Accept Mission',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      12.verticalSpace,

                      OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ScoutColors.textSecondary,
                          side: const BorderSide(
                            color: ScoutColors.divider,
                            width: 1.2,
                          ),
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Decline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    20.verticalSpace,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Back button ───────────────────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
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

// ── Distance badge ────────────────────────────────────────────────────────────
class _DistanceBadge extends StatelessWidget {
  final String label;

  const _DistanceBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: ScoutColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(Icons.location_on, color: ScoutColors.scoutMarker, size: 36),
          10.verticalSpace,
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ScoutColors.scoutMarker,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail card wrapper ───────────────────────────────────────────────────────
class _DetailCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ScoutColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: ScoutColors.divider,
      height: 1,
      thickness: 1,
      indent: 18,
      endIndent: 18,
    );
  }
}

// ── Simple label / value row ──────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: ScoutColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? ScoutColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Instructions row ──────────────────────────────────────────────────────────
class _InstructionsRow extends StatelessWidget {
  final String text;

  const _InstructionsRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INSTRUCTIONS',
            style: TextStyle(
              color: ScoutColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          10.verticalSpace,
          Text(
            text,
            style: const TextStyle(
              color: ScoutColors.textPrimary,
              fontSize: 14.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Client row ────────────────────────────────────────────────────────────────
class _ClientRow extends StatelessWidget {
  final String name;
  final double rating;
  final int missions;

  const _ClientRow({
    required this.name,
    required this.rating,
    required this.missions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'CLIENT',
            style: TextStyle(
              color: ScoutColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: ScoutColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.star, color: ScoutColors.primary, size: 14),
              const SizedBox(width: 3),
              Text(
                '$rating',
                style: const TextStyle(
                  color: ScoutColors.textAccent,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
