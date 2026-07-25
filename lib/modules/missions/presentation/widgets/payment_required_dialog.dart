import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';

class PaymentRequiredDialog extends StatefulWidget {
  final MissionEntity mission;

  /// Opens the payment sheet for [mission].
  final Future<void> Function() onPay;

  const PaymentRequiredDialog({
    super.key,
    required this.mission,
    required this.onPay,
  });

  @override
  State<PaymentRequiredDialog> createState() => _PaymentRequiredDialogState();
}

class _PaymentRequiredDialogState extends State<PaymentRequiredDialog> {
  Timer? _ticker;
  Duration? _left;

  @override
  void initState() {
    super.initState();
    _left = widget.mission.paymentTimeLeft;
    if (_left != null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _left = widget.mission.paymentTimeLeft);
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String? get _countdownLabel {
    final left = _left;
    if (left == null) return null;
    final m = left.inMinutes.toString().padLeft(2, '0');
    final s = (left.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    final guide = mission.scout?.firstName?.trim();
    final countdown = _countdownLabel;

    return Dialog(
      backgroundColor: ClientColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ────────────────────────────────────────────────────────
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ClientColors.primary.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                color: ClientColors.primary,
                size: 32,
              ),
            ),

            const SizedBox(height: 16),

            // ── Title ───────────────────────────────────────────────────────
            Text(
              (guide?.isNotEmpty ?? false)
                  ? 'Guide $guide accepted!'
                  : 'Your guide accepted!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ClientColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            // ── Subtitle ────────────────────────────────────────────────────
            Text(
              mission.address,
              textAlign: TextAlign.center,
              style: TextStyle(color: ClientColors.textSecondary, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // ── Amount ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: ClientColors.inputBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    'AMOUNT DUE',
                    style: TextStyle(
                      color: ClientColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mission.formattedPrice,
                    style: TextStyle(
                      color: ClientColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Description ─────────────────────────────────────────────────
            Text(
              countdown != null
                  ? 'Pay now to confirm your live check. We’ll hold your slot '
                        'for $countdown.'
                  : 'Pay now to confirm your live check — your guide can’t '
                        'start until payment goes through.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ClientColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // ── Action buttons ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: Get.back,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ClientColors.textSecondary,
                      side: BorderSide(
                        color: const Color.fromARGB(255, 4, 4, 5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Later',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      widget.onPay();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClientColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Pay Now',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
