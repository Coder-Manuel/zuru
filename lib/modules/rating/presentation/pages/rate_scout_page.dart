import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/rating/presentation/controllers/rating.controller.dart';

/// "Mission Complete" screen — shown when the room ends.
///
/// Pass the completed [MissionEntity] as `Get.arguments`.
class RateScoutPage extends GetView<RatingController> {
  static const String route = '/rate-scout';
  const RateScoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Animated checkmark ─────────────────────────────────────
              ScaleTransition(
                scale: controller.checkScale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: ClientColors.primary,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.black87,
                    size: 52,
                  ),
                ),
              ),

              28.verticalSpace,

              // ── Mission complete title ─────────────────────────────────
              const Text(
                'Mission Complete!',
                style: TextStyle(
                  color: ClientColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),

              16.verticalSpace,

              // ── Payment confirmation ───────────────────────────────────
              Text(
                controller.paymentText,
                style: const TextStyle(
                  color: ClientColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 1),

              // ── Rating card ────────────────────────────────────────────
              Obx(() {
                return _RatingCard(
                  scoutName: controller.scoutName,
                  selectedStars: controller.selectedStars.value,
                  onStarTapped: (i) => controller.selectedStars.value = i + 1,
                );
              }),

              const Spacer(flex: 2),

              // ── Back to Home button ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Obx(() {
                  return ElevatedButton(
                    onPressed: controller.createRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClientColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      controller.selectedStars.value > 0
                          ? 'Rate Scout'
                          : 'Back to Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                }),
              ),

              24.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Rating card ─────────────────────────────────────────────────────────────

class _RatingCard extends StatelessWidget {
  final String scoutName;
  final int selectedStars;
  final void Function(int index) onStarTapped;

  const _RatingCard({
    required this.scoutName,
    required this.selectedStars,
    required this.onStarTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: ClientColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClientColors.divider.withAlpha(60), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'RATE ${scoutName.toUpperCase()}',
            style: const TextStyle(
              color: ClientColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          20.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < selectedStars;
              return GestureDetector(
                onTap: () => onStarTapped(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      key: ValueKey(filled),
                      color: filled
                          ? ClientColors.primary
                          : ClientColors.textSecondary.withAlpha(120),
                      size: 38,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
