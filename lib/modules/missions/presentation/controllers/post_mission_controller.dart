import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:zuru/core/utils/loader.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/usecases/post_mission.usecase.dart';
import 'package:zuru/modules/missions/presentation/pages/finding_scouts_page.dart';
import 'package:zuru/modules/missions/presentation/pages/location_picker_page.dart';

class PostMissionController extends GetxController {
  final _postMissionUseCase = Get.find<PostMissionUseCase>();

  // ── Form fields ──────────────────────────────────────────────────────────
  final descriptionCTRL = TextEditingController();

  /// Duration options in minutes shown in the dropdown.
  final List<int> durations = const [2, 5, 10, 15, 20, 30];

  /// Currently selected duration in minutes (null = nothing chosen yet).
  final Rxn<int> selectedDuration = Rxn<int>();

  /// Mission type options.
  final List<MissionType> missionTypes = MissionType.values;

  /// Currently selected mission type (null = nothing chosen yet).
  final Rxn<MissionType> selectedMissionType = Rxn<MissionType>();

  // ── Location (set via LocationPickerPage) ────────────────────────────────
  final RxString address = ''.obs;
  final RxString currency = 'USD'.obs;
  final RxDouble latitude = 0.0.obs;
  final RxDouble longitude = 0.0.obs;

  /// True once the user has confirmed a location from the picker.
  final RxBool hasLocation = false.obs;

  // ── Price ────────────────────────────────────────────────────────────────
  final List<int> prices = const [10, 20, 35, 50];
  final RxInt selectedPriceIndex = 1.obs;

  int get selectedPrice => prices[selectedPriceIndex.value];

  void selectPrice(int index) => selectedPriceIndex.value = index;

  // ── Location picker ──────────────────────────────────────────────────────

  void openLocationPicker() => Get.toNamed(LocationPickerPage.route);

  /// Called by [LocationPickerController] when the user confirms a location.
  void setLocation({
    required String address,
    required double latitude,
    required double longitude,
  }) {
    this.address.value = address;
    this.latitude.value = latitude;
    this.longitude.value = longitude;
    hasLocation.value = true;
  }

  // ── Post mission ─────────────────────────────────────────────────────────

  Future<void> postMission(GlobalKey<FormState> formKey) async {
    if (!hasLocation.value) {
      Toast.error('Please set a location for the mission first.');
      return;
    }
    if (formKey.currentState?.validate() != true) return;

    // Convert selected minutes → seconds for the DB
    final durationInSec = (selectedDuration.value ?? 5) * 60;

    Loader.show(message: 'Posting mission...');
    final response = await _postMissionUseCase(
      PostMissionInput(
        address: address.value,
        latitude: latitude.value,
        longitude: longitude.value,
        description: descriptionCTRL.text.trim(),
        currency: currency.value,
        price: selectedPrice.toDouble(),
        durationInSec: durationInSec,
        missionType: selectedMissionType.value ?? MissionType.surveillance,
      ),
    );
    Loader.dismiss();

    response.fold(
      (ex) => Toast.error(ex.message),
      // Pass the created MissionEntity as a GetX argument so
      // FindingScoutsController can read the mission id + location
      // for the nearby-scouts fetch and the Realtime subscription.
      (mission) => Get.offNamed(FindingScoutsPage.route, arguments: mission),
    );
  }

  @override
  void onClose() {
    descriptionCTRL.dispose();
    super.onClose();
  }
}
