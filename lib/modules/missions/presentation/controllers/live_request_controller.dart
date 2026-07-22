import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:zuru/core/entities/profile.entity.dart';
import 'package:zuru/core/entities/session_pricing.entity.dart';
import 'package:zuru/core/routes/app_routes.dart';
import 'package:zuru/core/utils/loader.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/missions/data/models/live_request.input.dart';
import 'package:zuru/modules/missions/domain/usecases/create_live_request.usecase.dart';

enum LiveWhen { now, schedule }

class LiveRequestController extends GetxController {
  final _createLiveRequest = Get.find<CreateLiveRequestUseCase>();

  static const int maxDescriptionChars = 140;
  static const double platformFeeRate = 0.20;

  /// The scout being requested (passed as [Get.arguments]).
  late final Profile scout;

  final formKey = GlobalKey<FormState>();
  final descriptionCTRL = TextEditingController();

  final Rxn<SessionPricing> selectedTier = Rxn<SessionPricing>();
  final Rx<LiveWhen> whenMode = LiveWhen.now.obs;
  final Rxn<DateTime> selectedDate = Rxn<DateTime>();
  final Rxn<DateTime> selectedSlot = Rxn<DateTime>();
  final RxBool isSubmitting = false.obs;

  /// Selectable calendar days (today + next 9 days, midnight-aligned).
  late final List<DateTime> dateOptions;

  List<SessionPricing> get tiers => scout.sessionPricing;
  bool get hasPricing => tiers.isNotEmpty;

  // ── Money ──────────────────────────────────────────────────────────────────
  String get currency => selectedTier.value?.currency ?? 'KES';
  num get sessionFee => selectedTier.value?.price ?? 0;
  num get platformFee => sessionFee * platformFeeRate;
  num get total => sessionFee + platformFee;

  @override
  void onInit() {
    super.onInit();
    scout = Get.arguments as Profile;

    // Default to the first pricing tier so the breakdown is populated.
    if (tiers.isNotEmpty) selectedTier.value = tiers.first;

    final today = _dateOnly(DateTime.now());
    dateOptions = List.generate(10, (i) => today.add(Duration(days: i)));
  }

  @override
  void onClose() {
    descriptionCTRL.dispose();
    super.onClose();
  }

  // ── Selection ──────────────────────────────────────────────────────────────

  void selectTier(SessionPricing tier) => selectedTier.value = tier;

  void setWhen(LiveWhen mode) {
    whenMode.value = mode;
    if (mode == LiveWhen.schedule && selectedDate.value == null) {
      selectedDate.value = dateOptions.first;
    }
  }

  void selectDate(DateTime date) {
    selectedDate.value = _dateOnly(date);
    // Drop a slot that no longer belongs to the newly-picked day.
    final slot = selectedSlot.value;
    if (slot != null && !_isSameDay(slot, date)) {
      selectedSlot.value = null;
    }
  }

  void selectSlot(DateTime slot) => selectedSlot.value = slot;

  /// 30-minute slots between 08:00–20:00 for the selected day; past slots are
  /// excluded for today.
  List<DateTime> get timeSlots {
    final date = selectedDate.value;
    if (date == null) return const [];
    final now = DateTime.now();
    final slots = <DateTime>[];
    for (var h = 8; h <= 18; h++) {
      for (final m in const [0, 30]) {
        final slot = DateTime(date.year, date.month, date.day, h, m);
        if (slot.isAfter(now.add(const Duration(minutes: 15)))) {
          slots.add(slot);
        }
      }
    }
    return slots;
  }

  /// The resolved schedule, or null when "now".
  DateTime? get scheduledAt => whenMode.value == LiveWhen.schedule
      ? selectedSlot.value
      : DateTime.now().add(const Duration(hours: 2));

  // ── Submit ───────────────────────────────────────────────────────────────

  Future<void> submit() async {
    final tier = selectedTier.value;
    if (tier == null) {
      Toast.error('This guide has no session pricing yet');
      return;
    }
    if (formKey.currentState?.validate() != true) {
      Toast.error('Please fill in all the required fields');
      return;
    }
    if (whenMode.value == LiveWhen.schedule && selectedSlot.value == null) {
      Toast.error('Pick a date and time for your session');
      return;
    }
    final scoutId = scout.id;
    if (scoutId == null) {
      Toast.error('Guide unavailable, please go back and retry');
      return;
    }

    final schedule = scheduledAt;

    isSubmitting.value = true;
    Loader.show(message: 'Sending request…');

    final result = await _createLiveRequest(
      LiveRequestInput(
        scoutId: scoutId,
        description: descriptionCTRL.text.trim(),
        currency: tier.currency,
        price: total.toDouble(),
        durationInSec: tier.durationMinutes * 60,
        scheduledAt: schedule,
        address: scout.locality,
        lat: scout.localityGeo?.lat,
        lng: scout.localityGeo?.lng,
      ),
    );

    Loader.dismiss();
    isSubmitting.value = false;

    result.fold((err) => Toast.error(err.message), (mission) {
      Get.offNamed(
        AppRoutes.requestSent,
        arguments: {
          'scoutName': scout.fullName,
          'scheduledAt': schedule?.toIso8601String(),
        },
      );
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
