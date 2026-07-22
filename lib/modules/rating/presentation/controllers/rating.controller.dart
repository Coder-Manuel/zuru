import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/core/utils/loader.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/presentation/pages/mission_complete_page.dart';
import 'package:zuru/modules/rating/data/models/rating.input.dart';
import 'package:zuru/modules/rating/domain/usecases/create_rating.usecase.dart';

class RatingController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final CreateRatingUseCase _createRatingUsecase;

  RatingController({required CreateRatingUseCase createRatingUsecase})
    : _createRatingUsecase = createRatingUsecase;

  late final MissionEntity mission;
  Rx<int> selectedStars = 0.obs;

  late final AnimationController checkCtrl;
  late final Animation<double> checkScale;

  Rx<bool> isRating = false.obs;

  // ── Client view ───────────────────────────────────────────────────────────
  String get scoutName => mission.scout?.displayName ?? 'Guide';

  String get paymentText =>
      'Payment of ${mission.currency} ${mission.price.toStringAsFixed(2)} '
      'has been released to $scoutName.';

  // ── Scout view ────────────────────────────────────────────────────────────
  String get clientName => mission.client?.displayName ?? 'Viewer';

  void onContinue() =>
      Get.offNamed(MissionCompletePage.route, arguments: mission);

  @override
  void onInit() {
    checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    mission = Get.arguments as MissionEntity;
    checkScale = CurvedAnimation(parent: checkCtrl, curve: Curves.elasticOut);
    // Pop the check icon in on entry.
    checkCtrl.forward();
    super.onInit();
  }

  Future<void> createRating() async {
    if (selectedStars.value <= 0) return onBackToHome();
    Loader.show(message: 'Posting rating...');
    final response = await _createRatingUsecase(
      CreateRatingInput(
        missionId: mission.id ?? '',
        toUserId: mission.scoutId ?? '',
        score: selectedStars.value,
      ),
    );
    Loader.dismiss();

    response.fold((ex) => Toast.error(ex.message), (_) {
      Toast.success('Rating Submitted');
      onBackToHome();
    });
  }

  void onBackToHome() => Get.until((route) => route.isFirst);

  @override
  void onClose() {
    checkCtrl.dispose();
    super.onClose();
  }
}
