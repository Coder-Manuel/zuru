import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/home/presentation/controllers/maps_tab_controller.dart';

/// Accent for the pre-payment states — matches the "Unpaid" badge on the
/// missions tab.
const _amber = Color(0xFFF5A020);

/// A pulsing "payment due" beacon overlaid on the client's map — the mirror of
/// the guide's incoming-requests beacon.
///
/// Appears once a guide accepts a live request and stays put until the payment
/// lands, so dismissing the accept dialog doesn't bury the fact that money is
/// owed and the guide is waiting. Tapping re-opens the notice.
class PaymentDueBeacon extends StatefulWidget {
  const PaymentDueBeacon({super.key});

  @override
  State<PaymentDueBeacon> createState() => _PaymentDueBeaconState();
}

class _PaymentDueBeaconState extends State<PaymentDueBeacon>
    with SingleTickerProviderStateMixin {
  final controller = Get.find<MapsTabController>();
  late final AnimationController _pulse;

  /// Drives the countdown label; the beacon itself is rebuilt by [Obx].
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final due = controller.paymentDueMissions;
      if (due.isEmpty) return const SizedBox.shrink();

      final mission = due.first;
      final count = due.length;
      final left = mission.paymentTimeLeft;
      final subtitle = left == null
          ? 'Tap to pay ${mission.formattedPrice}'
          : 'Pay within ${_clock(left)} · ${mission.formattedPrice}';

      return GestureDetector(
        onTap: () => controller.promptPaymentFor(mission),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Expanding ping ring behind the pill.
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) {
                final t = _pulse.value;
                return Container(
                  width: 60 + 44 * t,
                  height: 60 + 44 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _amber.withAlpha(((1 - t) * 140).round()),
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
                color: ClientColors.surface,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: _amber.withAlpha(150)),
                boxShadow: [
                  BoxShadow(
                    color: _amber.withAlpha(70),
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
                          color: _amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          color: Colors.black,
                          size: 20,
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
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ClientColors.surface,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              '$count',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
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
                            ? 'Payment required'
                            : '$count payments required',
                        style: TextStyle(
                          color: ClientColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(color: _amber, fontSize: 11),
                      ),
                    ],
                  ),
                  6.horizontalSpace,
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _amber,
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

  /// MM:SS, or H:MM:SS once the window is longer than an hour.
  static String _clock(Duration d) {
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }
}
