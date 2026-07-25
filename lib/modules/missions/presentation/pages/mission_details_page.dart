import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
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

    log('==== MISSION_S: ${mission.status}');

    return Scaffold(
      backgroundColor: ClientColors.background,
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
                  Text(
                    'Live Check Details',
                    style: TextStyle(
                      color: ClientColors.textPrimary,
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
                          valueColor: ClientColors.primary,
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
                          name: mission.client?.displayName ?? 'Viewer',
                          rating: mission.client?.rating ?? 0,
                          missions: mission.client?.totalReviews ?? 0,
                        ),
                      ],
                    ),

                    32.verticalSpace,

                    // ── CTA area ─────────────────────────────────────────
                    if (mission.isMyMission) ...[
                      _OwnMissionNotice(),
                    ] else
                      _ScoutCta(mission: mission),

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

// ── Scout CTA ─────────────────────────────────────────────────────────────────

/// Accept / Decline, or the post-acceptance CTA.
///
/// Reads the live copy of the mission from [RadarController] when it is the
/// scout's active one, so the "awaiting payment" lock lifts by itself the
/// moment the client's payment publishes the mission.
class _ScoutCta extends GetView<RadarController> {
  final MissionEntity mission;

  const _ScoutCta({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = controller.activeMission.value;
      final current = (active != null && active.id == mission.id)
          ? active
          : mission;

      // Accepted but unpaid — the guide holds the slot and waits.
      if (current.awaitingClientPayment) {
        return _AwaitingPaymentNotice(countdown: controller.paymentCountdown);
      }

      if ([
        MissionStatus.accepted,
        MissionStatus.enroute,
      ].contains(current.status)) {
        // Accepted and paid → show navigation CTA
        return ElevatedButton.icon(
          onPressed: () =>
              Get.toNamed(NavigationPage.route, arguments: current),
          icon: const Icon(Icons.navigation_rounded, size: 20),
          label: const Text(
            'Navigate to Location',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ClientColors.primary,
            foregroundColor: ClientColors.background,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        );
      }

      // Open mission / pending request → Accept / Decline
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (current.isLiveRequest && !current.isPublished) ...[
            _PayOnAcceptHint(),
            16.verticalSpace,
          ],
          ElevatedButton(
            onPressed: controller.isAccepting.value
                ? null
                : () => controller.acceptMission(current),
            style: ElevatedButton.styleFrom(
              backgroundColor: ClientColors.primary,
              foregroundColor: ClientColors.background,
              disabledBackgroundColor: ClientColors.primary.withAlpha(100),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: controller.isAccepting.value
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: ClientColors.background,
                    ),
                  )
                : const Text(
                    'Accept Live Check',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),

          12.verticalSpace,

          OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              foregroundColor: ClientColors.textSecondary,
              side: BorderSide(color: ClientColors.divider, width: 1.2),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Decline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    });
  }
}

/// Tells the guide up front that accepting a live request triggers the
/// client's payment, not the trip.
class _PayOnAcceptHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ClientColors.divider.withAlpha(120)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: ClientColors.textSecondary,
          ),
          12.horizontalSpace,
          Expanded(
            child: Text(
              'Accepting asks the client to pay. You can set off as soon as '
              'their payment clears.',
              style: TextStyle(
                color: ClientColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Locked state between acceptance and payment.
class _AwaitingPaymentNotice extends StatelessWidget {
  final RxString countdown;

  const _AwaitingPaymentNotice({required this.countdown});

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFF5A020);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: amber.withAlpha(18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: amber.withAlpha(90)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_clock_rounded, color: amber, size: 22),
                  12.horizontalSpace,
                  const Expanded(
                    child: Text(
                      'Waiting for client payment',
                      style: TextStyle(
                        color: amber,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Obx(
                    () => Text(
                      countdown.value,
                      style: const TextStyle(
                        color: amber,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              12.verticalSpace,
              Text(
                'This live check is yours once the client pays. Navigation '
                'unlocks automatically — don’t set off yet.',
                style: TextStyle(
                  color: ClientColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        12.verticalSpace,

        ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.navigation_rounded, size: 20),
          label: const Text(
            'Navigate to Location',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: ClientColors.primary.withAlpha(60),
            disabledForegroundColor: ClientColors.background.withAlpha(160),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}

// ── Own-mission notice ────────────────────────────────────────────────────────
class _OwnMissionNotice extends StatelessWidget {
  const _OwnMissionNotice();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withAlpha(40), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_pin_circle_outlined,
                  // color: bodyColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your live check',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "You posted this live check. It's visible to nearby guides who can accept it — you don't need to take any action here.",
                      style: TextStyle(fontSize: 13.5, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        10.verticalSpace,

        OutlinedButton(
          onPressed: () => Get.back(),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey, width: 1.2),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Go Back',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
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
          color: ClientColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.chevron_left,
          color: ClientColors.textPrimary,
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
        color: ClientColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(Icons.location_on, color: ClientColors.green, size: 36),
          10.verticalSpace,
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ClientColors.green,
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
        color: ClientColors.surface,
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
    return Divider(
      color: ClientColors.divider,
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
            style: TextStyle(
              color: ClientColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? ClientColors.textPrimary,
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
          Text(
            'INSTRUCTIONS',
            style: TextStyle(
              color: ClientColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          10.verticalSpace,
          Text(
            text,
            style: TextStyle(
              color: ClientColors.textPrimary,
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
          Text(
            'VIEWER',
            style: TextStyle(
              color: ClientColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          Row(
            children: [
              Text(
                name,
                style: TextStyle(
                  color: ClientColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.star, color: ClientColors.primary, size: 14),
              const SizedBox(width: 3),
              Text(
                '$rating',
                style: TextStyle(color: ClientColors.primary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
