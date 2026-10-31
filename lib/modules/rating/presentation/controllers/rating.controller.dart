import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/core/services/role_service/role_service.dart';
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

  /// The other side of the mission: the client rates the guide and the guide
  /// rates the client. Both pages share this controller, and always sending
  /// the scout had the guide rating themselves.
  String? get _ratedProfileId => RoleService.instance.isScout
      ? mission.clientId ?? mission.client?.id
      : mission.scoutId ?? mission.scout?.id;

  Future<void> createRating() async {
    if (selectedStars.value <= 0) return onBackToHome();
    final missionId = mission.id;
    final ratedId = _ratedProfileId;
    if (missionId == null || ratedId == null) {
      return Toast.error('Could not find who to rate for this live check.');
    }

    Loader.show(message: 'Posting rating...');
    final response = await _createRatingUsecase(
      CreateRatingInput(
        missionId: missionId,
        toUserId: ratedId,
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
