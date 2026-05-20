import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/rating/presentation/controllers/rating.controller.dart';

/// Simple stub rate-mission page — shown after a LiveKit room terminates.
///
/// Pass the finished [MissionEntity] as `Get.arguments`.
class RateClientPage extends GetView<RatingController> {
  static const String route = '/rate-client';

  const RateClientPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 6),
              // ── Mission complete title ─────────────────────────────────
              const Text(
                'Mission Complete!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),

              50.verticalSpace,

              // ── Animated checkmark ─────────────────────────────────────
              ScaleTransition(
                scale: controller.checkScale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.black87,
                    size: 52,
                  ),
                ),
              ),

              28.verticalSpace,

              const Text(
                'How was your mission?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              12.verticalSpace,
              Text(
                'Rate your experience with ${controller.clientName}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              40.verticalSpace,
              // ── Star rating row ──────────────────────────────────────────
              Obx(() {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final index = i + 1;
                    final filled = index <= controller.selectedStars.value;
                    return GestureDetector(
                      onTap: () => controller.selectedStars.value = index,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: filled
                              ? const Color(0xFFFFD700)
                              : AppColors.textSecondary,
                          size: 44,
                        ),
                      ),
                    );
                  }),
                );
              }),
              const Spacer(flex: 9),
              Obx(() {
                return ElevatedButton(
                  onPressed: controller.selectedStars.value == 0
                      ? null
                      : controller.createRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    disabledBackgroundColor: AppColors.primary.withAlpha(80),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Submit Rating',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                );
              }),

              12.verticalSpace,

              TextButton(
                onPressed: controller.onContinue,
                child: const Text(
                  'Skip',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),

              16.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
