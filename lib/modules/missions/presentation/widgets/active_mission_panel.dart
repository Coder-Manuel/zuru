import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/utils/extensions.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/core/widgets/location_listener.builder.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/presentation/controllers/radar_controller.dart';
import 'package:zuru/modules/missions/presentation/pages/mission_details_page.dart';

class ActiveMissionPanel extends GetView<RadarController> {
  const ActiveMissionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ScoutColors.background,
      child: Obx(() {
        final mission = controller.activeMission.value;
        if (mission == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  _PulsingDot(),
                  10.horizontalSpace,
                  Text(
                    'LIVE CHECK IN ACTION',
                    style: TextStyle(
                      color: ScoutColors.scoutMarker,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mission card — tap to view full details + Navigate CTA
                    GestureDetector(
                      onTap: () => Get.toNamed(
                        MissionDetailsPage.route,
                        arguments: mission,
                      ),
                      child: _ActiveMissionCard(mission: mission),
                    ),

                    16.verticalSpace,

                    // Countdown block
                    _CountdownCard(countdown: controller.countdown.value),

                    20.verticalSpace,

                    // Complete CTA
                    Obx(
                      () => ElevatedButton(
                        onPressed: controller.isUpdatingStatus.value
                            ? null
                            : controller.completeMission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ScoutColors.primary,
                          foregroundColor: ScoutColors.background,
                          disabledBackgroundColor: ScoutColors.primary
                              .withAlpha(100),
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: controller.isUpdatingStatus.value
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ScoutColors.background,
                                ),
                              )
                            : const Text(
                                'Complete Live Check',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    10.verticalSpace,

                    // Abandon CTA
                    Obx(
                      () => OutlinedButton(
                        onPressed: controller.isUpdatingStatus.value
                            ? null
                            : () => _confirmAbandon(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF4444),
                          side: const BorderSide(
                            color: Color(0xFF3B1A1A),
                            width: 1.2,
                          ),
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Abandon Live Check',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _confirmAbandon(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ScoutColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Abandon Live Check?',
          style: TextStyle(
            color: ScoutColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'This live check will be released back to the pool. This action cannot be undone.',
          style: TextStyle(
            color: ScoutColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: ScoutColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.abandonMission();
            },
            child: const Text(
              'Abandon',
              style: TextStyle(
                color: Color(0xFFFF4444),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active mission card ───────────────────────────────────────────────────────

class _ActiveMissionCard extends StatelessWidget {
  final MissionEntity mission;
  const _ActiveMissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ScoutColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ScoutColors.scoutMarker.withAlpha(60),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type / address
          Text(
            '${mission.type?.label}\n${mission.address}',
            style: TextStyle(
              color: ScoutColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              height: 1.4,
            ),
          ),

          14.verticalSpace,

          // Meta row
          Row(
            children: [
              _MetaChip(
                icon: Icons.timer_outlined,
                label: '${(mission.durationInSec / 60).round()} min',
              ),
              10.horizontalSpace,
              LocationListenerBuilder(
                latitude: mission.latitude ?? 0.0,
                longitude: mission.longitude ?? 0.0,
                builder: (_, distance) {
                  return _MetaChip(
                    icon: Icons.location_on_outlined,
                    label: distance?.formatDistance ?? '--',
                  );
                },
              ),
            ],
          ),

          14.verticalSpace,

          Divider(color: ScoutColors.divider, height: 1, thickness: 1),

          14.verticalSpace,

          // Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PAYOUT',
                style: TextStyle(
                  color: ScoutColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                mission.formattedPrice,
                style: TextStyle(
                  color: ScoutColors.textAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ScoutColors.primary),
        5.horizontalSpace,
        Text(
          label,
          style: TextStyle(color: ScoutColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

// ── Countdown card ────────────────────────────────────────────────────────────

class _CountdownCard extends StatelessWidget {
  final String countdown;
  const _CountdownCard({required this.countdown});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: ScoutColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EXPIRES IN',
                style: TextStyle(
                  color: ScoutColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              6.verticalSpace,
              Text(
                'Live Check removed after 5 hours',
                style: TextStyle(
                  color: ScoutColors.textSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: ScoutColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: ScoutColors.scoutMarker.withAlpha(80),
                width: 1,
              ),
            ),
            child: Text(
              countdown,
              style: TextStyle(
                color: ScoutColors.scoutMarker,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pulsing status dot ────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ScoutColors.scoutMarker,
        ),
      ),
    );
  }
}
