import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:zuru/core/services/fx_service/fx_service.dart';
import 'package:zuru/core/utils/extensions.dart';
import 'package:zuru/core/utils/loader.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/usecases/post_mission.usecase.dart';
import 'package:zuru/modules/missions/presentation/pages/finding_scouts_page.dart';
import 'package:zuru/modules/missions/presentation/pages/location_picker_page.dart';
import 'package:zuru/modules/payments/presentation/widgets/payment_sheet.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

class PostMissionController extends GetxController {
  final _postMissionUseCase = Get.find<PostMissionUseCase>();
  final _fx = Get.find<FxService>();

  // ── Form fields ──────────────────────────────────────────────────────────
  final descriptionCTRL = TextEditingController();

  /// Duration options in minutes shown in the dropdown.
  final List<int> durations = const [10, 15, 20, 30, 45, 60];

  /// Currently selected duration in minutes (null = nothing chosen yet).
  final Rxn<int> selectedDuration = Rxn<int>();

  void selectDuration(int? v) {
    selectedDuration.value = v;
    selectedPriceIndex.value = 0; // ranges change with duration
  }

  /// Mission type options.
  final List<MissionType> missionTypes = MissionType.values;

  /// Currently selected mission type (null = nothing chosen yet).
  final Rxn<MissionType> selectedMissionType = Rxn<MissionType>();

  // ── Location (set via LocationPickerPage) ────────────────────────────────
  final RxString address = ''.obs;
  final RxDouble latitude = 0.0.obs;
  final RxDouble longitude = 0.0.obs;

  /// True once the user has confirmed a location from the picker.
  final RxBool hasLocation = false.obs;

  // ── Currency ──────────────────────────────────────────────────────────────
  final Rx<Currency> currency = Currency.usd.obs;

  void setCurrency(Currency c) {
    currency.value = c;
    selectedPriceIndex.value = 0;
  }

  /// Live USD → KES rate (whole number), for the "live rate" hint.
  double get usdToKes => _fx.usdToKes.value;

  // ── Price ────────────────────────────────────────────────────────────────
  /// Offer presets in **USD**, keyed by duration (minutes). The range scales up
  /// with duration (10 min ≈ \$3–5 … 60 min ≈ \$25–40). Edit freely.
  static const Map<int, List<int>> _usdPriceOptions = {
    10: [3, 4, 5],
    15: [5, 7, 9],
    20: [8, 10, 13],
    30: [13, 17, 22],
    45: [18, 24, 30],
    60: [25, 32, 40],
  };

  final RxInt selectedPriceIndex = 0.obs;

  List<int> get _usdOptions =>
      _usdPriceOptions[selectedDuration.value] ?? const [];

  /// Offer options in the **selected currency**, whole numbers. KES values are
  /// derived live from [FxService]; reads here are reactive.
  List<int> get priceOptions => currency.value == Currency.kes
      ? _usdOptions.map((usd) => _fx.toKes(usd)).toList()
      : _usdOptions;

  int get selectedPrice {
    final opts = priceOptions;
    if (opts.isEmpty) return 0;
    return opts[selectedPriceIndex.value.clamp(0, opts.length - 1)];
  }

  void selectPrice(int index) => selectedPriceIndex.value = index;

  /// The offer converted to KES — M-Pesa charges in KES, so we store the KES
  /// amount on the mission. USD offers are converted via [FxService]; KES offers
  /// pass through.
  int get payableKes => currency.value == Currency.kes
      ? selectedPrice
      : _fx.toKes(selectedPrice);

  /// Formatted chip/label for an amount in the selected currency.
  String priceLabel(int amount) => currency.value == Currency.kes
      ? 'KSh ${amount.asCurrency}'
      : '\$$amount';

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
      Toast.error('Please set a location for the live check first.');
      return;
    }
    if (formKey.currentState?.validate() != true) return;

    // Convert selected minutes → seconds for the DB
    final durationInSec = (selectedDuration.value ?? 5) * 60;

    Loader.show(message: 'Posting live check...');
    final response = await _postMissionUseCase(
      PostMissionInput(
        address: address.value,
        latitude: latitude.value,
        longitude: longitude.value,
        description: descriptionCTRL.text.trim(),
        currency: Currency.kes.code,
        price: payableKes.toDouble(),
        durationInSec: durationInSec,
        missionType: selectedMissionType.value ?? MissionType.surveillance,
      ),
    );
    Loader.dismiss();

    response.fold((ex) => Toast.error(ex.message), (mission) async {
      final missionId = mission.id;
      if (missionId == null) {
        Toast.error('Something went wrong. Please try again.');
        return;
      }

      final paid = await showPaymentSheet(
        missionId: missionId,
        amountLabel: mission.formattedPrice,
        phone: Get.find<UserController>().currentUser.value?.phone,
      );
      if (!paid) return;

      Get.offNamed(FindingScoutsPage.route, arguments: mission);
    });
  }

  @override
  void onClose() {
    descriptionCTRL.dispose();
    super.onClose();
  }
}
