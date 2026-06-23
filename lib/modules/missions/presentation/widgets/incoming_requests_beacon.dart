import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/missions/presentation/controllers/radar_controller.dart';
import 'package:zuru/modules/missions/presentation/widgets/incoming_requests_sheet.dart';

/// A pulsing "incoming requests" beacon overlaid on the radar map.
///
/// Stays hidden until a client targets this scout with a request, then animates
/// in with an expanding radar-ping ring to grab attention. Tapping opens the
/// [showIncomingRequestsSheet] review sheet.
class IncomingRequestsBeacon extends StatefulWidget {
  const IncomingRequestsBeacon({super.key});

  @override
  State<IncomingRequestsBeacon> createState() => _IncomingRequestsBeaconState();
}

class _IncomingRequestsBeaconState extends State<IncomingRequestsBeacon>
    with SingleTickerProviderStateMixin {
  final controller = Get.find<RadarController>();
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.hasPendingRequests) return const SizedBox.shrink();

      final count = controller.pendingRequestCount;

      return GestureDetector(
        onTap: () => showIncomingRequestsSheet(context),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Expanding radar-ping ring behind the pill.
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) {
                final t = _pulse.value;
                return Container(
                  width: 60 + 40 * t,
                  height: 60 + 40 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ScoutColors.primary.withAlpha(
                        ((1 - t) * 120).round(),
                      ),
                      width: 2,
                    ),
                  ),
                );
              },
            ),

            // The pill.
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              decoration: BoxDecoration(
                color: ScoutColors.surface,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: ScoutColors.primary.withAlpha(120)),
                boxShadow: [
                  BoxShadow(
                    color: ScoutColors.primaryGlow,
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon badge with the live count.
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: ScoutColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: ScoutColors.background,
                          size: 22,
                        ),
                      ),
                      if (count > 1)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(minWidth: 18),
                            decoration: BoxDecoration(
                              color: ScoutColors.scoutMarker,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ScoutColors.surface,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              '$count',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: ScoutColors.background,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  10.horizontalSpace,
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        count == 1
                            ? 'Incoming request'
                            : '$count incoming requests',
                        style: const TextStyle(
                          color: ScoutColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Tap to review',
                        style: TextStyle(
                          color: ScoutColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  6.horizontalSpace,
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: ScoutColors.textAccent,
                    size: 22,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
