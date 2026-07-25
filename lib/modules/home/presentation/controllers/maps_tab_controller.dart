import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/entities/session.entity.dart';
import 'package:zuru/modules/missions/domain/usecases/watch_active_missions.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/watch_active_session.usecase.dart';
import 'package:zuru/modules/missions/presentation/widgets/payment_required_dialog.dart';
import 'package:zuru/modules/payments/presentation/widgets/payment_sheet.dart';
import 'package:zuru/modules/stream/presentation/widgets/join_stream_dialog.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

class MapsTabController extends GetxController {
  final _watchActiveMissionsUseCase = Get.find<WatchActiveMissionsUseCase>();
  final _watchActiveSessionUseCase = Get.find<WatchActiveSessionUseCase>();

  // ── State ─────────────────────────────────────────────────────────────────
  final RxList<MissionEntity> activeMissions = <MissionEntity>[].obs;
  final RxBool isLoading = true.obs;
  Set<String> shownSessions = {};

  StreamSubscription<dynamic>? _missionSubscription;
  StreamSubscription<dynamic>? _sessionSubscription;

  @override
  void onReady() {
    _startActiveMissionsStream();
    super.onReady();
  }

  void _startActiveMissionsStream() {
    isLoading.value = true;
    _missionSubscription?.cancel();

    _missionSubscription = _watchActiveMissionsUseCase().listen(
      (response) {
        response.fold((error) => Toast.error(error.message), (data) {
          activeMissions.value = data;
          _startLiveSessionStream();
          _promptPendingPayment();
        });
        isLoading.value = false;
      },
      onError: (_) {
        isLoading.value = false;
        Toast.error('Failed to load live checks. Kindly retry.');
      },
    );
  }

  void _startLiveSessionStream() {
    _sessionSubscription?.cancel();
    final missions = activeMissions.map((m) => m.id ?? '').toList();
    _sessionSubscription = _watchActiveSessionUseCase(missions).listen(
      (response) {
        response.fold((_) => null, _onSession);
      },
      onError: (e) {
        log('===== ACTIVE-SESSION-ERROR: $e');
      },
    );
  }

  void _onSession(SessionEntity session) {
    if (session.roomName == null || session.hostToken == null) return;
    if (session.status == SessionStatus.ended) return;

    // Find the matching mission.
    final mission = activeMissions
        .where((m) => m.id == session.missionId)
        .firstOrNull;
    if (mission == null) return;
    if (shownSessions.contains(mission.id)) return;
    shownSessions.add(mission.id ?? '');

    // Show dialog.
    Get.dialog(JoinStreamDialog(mission: mission), barrierDismissible: true);
  }

  // ── Pay-on-accept prompt ──────────────────────────────────────────────────

  /// Requests we've already prompted for this session — the realtime stream
  /// re-emits on every mission change and must not re-open the dialog.
  final Set<String> _promptedPayments = {};

  /// Live requests a guide accepted that the client still owes payment on,
  /// most urgent (soonest deadline) first. Drives the map's payment beacon.
  List<MissionEntity> get paymentDueMissions {
    final due = activeMissions
        .where((m) => m.awaitingClientPayment && m.id != null)
        .toList();
    due.sort((a, b) {
      final da = a.paymentDeadline;
      final db = b.paymentDeadline;
      if (da == null) return db == null ? 0 : 1; // unknown deadlines last
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return due;
  }

  bool get hasPaymentDue => paymentDueMissions.isNotEmpty;

  /// Surfaces [PaymentRequiredDialog] for the first live request a guide has
  /// accepted but the client hasn't paid for yet.
  void _promptPendingPayment() {
    if (Get.isDialogOpen ?? false) return;

    final mission = paymentDueMissions
        .where((m) => !_promptedPayments.contains(m.id))
        .firstOrNull;
    if (mission == null) return;

    _promptedPayments.add(mission.id!);
    promptPaymentFor(mission);
  }

  /// Re-opens the accept notice for [mission] — used by the map beacon, which
  /// stays put after the initial prompt is dismissed.
  void promptPaymentFor(MissionEntity mission) {
    if (Get.isDialogOpen ?? false) return;

    Get.dialog(
      PaymentRequiredDialog(
        mission: mission,
        onPay: () => payForMission(mission),
      ),
      barrierDismissible: true,
    );
  }

  /// Collects payment for an accepted-but-unpaid request. The backend publishes
  /// the mission on a successful payment, which unblocks the guide.
  Future<void> payForMission(MissionEntity mission) async {
    final id = mission.id;
    if (id == null) return;

    await showPaymentSheet(
      missionId: id,
      amountLabel: mission.formattedPrice,
      phone: Get.find<UserController>().currentUser.value?.phone,
    );
  }

  @override
  void onClose() {
    _sessionSubscription?.cancel();
    _missionSubscription?.cancel();
    super.onClose();
  }
}
