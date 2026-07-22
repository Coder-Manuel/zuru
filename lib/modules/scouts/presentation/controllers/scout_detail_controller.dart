import 'package:get/get.dart';
import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/routes/app_routes.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/scouts/domain/usecases/get_scout_detail.usecase.dart';

class ScoutDetailController extends GetxController {
  final GetScoutDetailUseCase _getScoutDetail;

  ScoutDetailController({required GetScoutDetailUseCase getScoutDetail})
    : _getScoutDetail = getScoutDetail;

  final Rxn<User> scout = Rxn<User>();
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  late final String _profileId;

  @override
  void onInit() {
    super.onInit();
    _profileId = (Get.arguments is String) ? Get.arguments as String : '';
    fetch();
  }

  Future<void> fetch() async {
    if (_profileId.isEmpty) {
      isLoading.value = false;
      error.value = 'Guide not found';
      return;
    }

    isLoading.value = true;
    error.value = null;

    final result = await _getScoutDetail(_profileId);
    isLoading.value = false;

    result.fold(
      (err) => error.value = err.message,
      (value) => scout.value = value,
    );
  }

  void requestLive() {
    final profile = scout.value?.scoutProfile;
    if (profile == null) {
      Toast.error('Guide details unavailable, please retry');
      return;
    }
    Get.toNamed(AppRoutes.liveRequest, arguments: profile);
  }
}
