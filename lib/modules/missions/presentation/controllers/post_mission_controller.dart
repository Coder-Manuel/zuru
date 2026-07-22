import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:zuru/core/services/fx_service/fx_service.dart';
import 'package:zuru/core/services/remote_config_service/remote_config_service.dart';
import 'package:zuru/core/utils/extensions.dart';
import 'package:zuru/core/utils/loader.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/data/models/mission_pricing.config.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/usecases/post_mission.usecase.dart';
import 'package:zuru/modules/missions/presentation/pages/finding_scouts_page.dart';
import 'package:zuru/modules/missions/presentation/pages/location_picker_page.dart';
import 'package:zuru/modules/payments/presentation/widgets/payment_sheet.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

class PostMissionController extends GetxController {
  final _postMissionUseCase = Get.find<PostMissionUseCase>();
  final _fx = Get.find<FxService>();
  final _remoteConfig = Get.find<RemoteConfigService>();

  // ── Form fields ──────────────────────────────────────────────────────────
  final descriptionCTRL = TextEditingController();

  /// Duration + pricing come from `app_config` (key `mission_pricing`), synced
  /// from the backend; falls back to bundled defaults offline / pre-sync.
  MissionPricingConfig get _pricing => MissionPricingConfig.fromSection(
    _remoteConfig.section('mission_pricing'),
  );

  /// Duration options in minutes shown in the dropdown.
  List<int> get durations => _pricing.durations;

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
  final RxInt selectedPriceIndex = 0.obs;

  Currency get _baseCurrency => _pricing.baseCurrency;

  /// Offer presets for the selected duration, in the config's declared base
  /// currency.
  List<int> get _baseOptions =>
      _pricing.options[selectedDuration.value] ?? const [];

  /// Canonical offer options for the selected duration, in the config's base
  /// currency. The chips iterate these; labels convert to the display currency.
  List<int> get offerOptions => _baseOptions;

  void selectPrice(int index) => selectedPriceIndex.value = index;

  int get _selectedBaseOffer {
    final base = _baseOptions;
    if (base.isEmpty) return 0;
    return base[selectedPriceIndex.value.clamp(0, base.length - 1)];
  }

  /// The offer converted to KES — M-Pesa charges in KES, so we store the KES
  /// amount on the mission regardless of the config's declared base currency.
  int get payableKes =>
      _fx.convert(_selectedBaseOffer, _baseCurrency, Currency.kes);

  /// Chip label: converts a base-currency offer to the selected display
  /// currency. KES shows whole; USD keeps up to 2 dp so small converted values
  /// don't collapse to \$0.
  String offerLabel(int baseAmount) {
    final amount = _fx.convertPrecise(
      baseAmount,
      _baseCurrency,
      currency.value,
    );
    return currency.value == Currency.kes
        ? 'KSh ${amount.round().asCurrency}'
        : _formatUsd(amount);
  }

  String _formatUsd(double amount) => amount == amount.roundToDouble()
      ? '\$${amount.toInt()}'
      : '\$${amount.toStringAsFixed(2)}';

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

  /// A live check created this session but not yet paid for. Kept so a retry
  /// resumes payment instead of creating a duplicate.
  MissionEntity? _pendingMission;
  final RxBool hasPendingPayment = false.obs;

  Future<void> postMission(GlobalKey<FormState> formKey) async {
    // Idempotency: if we already created a live check awaiting payment, resume
    // paying for it rather than posting another one.
    final pending = _pendingMission;
    if (pending != null) {
      await _collectPayment(pending);
      return;
    }

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

    response.fold((ex) => Toast.error(ex.message), (mission) {
      _pendingMission = mission;
      hasPendingPayment.value = true;
      _collectPayment(mission);
    });
  }

  Future<void> _collectPayment(MissionEntity mission) async {
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
    if (!paid) return; // keep the pending mission so a retry reuses it

    _pendingMission = null;
    hasPendingPayment.value = false;
    Get.offNamed(FindingScoutsPage.route, arguments: mission);
  }

  @override
  void onClose() {
    descriptionCTRL.dispose();
    super.onClose();
  }
}
