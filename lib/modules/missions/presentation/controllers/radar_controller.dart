import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/core/services/location_service/location_service.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/usecases/accept_mission.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/decline_mission.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/nearby_missions.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/watch_active_mission.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/watch_scout_requests.usecase.dart';
import 'package:zuru/modules/missions/presentation/pages/mission_details_page.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

class RadarController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final _watchNearbyUseCase = Get.find<NearbyMissionsUseCase>();
  final _watchActiveUseCase = Get.find<WatchActiveMissionUseCase>();
  final _watchRequestsUseCase = Get.find<WatchScoutRequestsUseCase>();
  final _acceptUseCase = Get.find<AcceptMissionUseCase>();
  final _declineMissionUseCase = Get.find<DeclineMissionUseCase>();
  final _locationService = Get.find<LocationService>();

  late final AnimationController sweepController;

  List<MissionEntity> missions = <MissionEntity>[].obs;
  final isLoading = true.obs;
  final isAccepting = false.obs;
  final isUpdatingStatus = false.obs;

  /// The scout's currently accepted mission. Null when none is active.
  final activeMission = Rx<MissionEntity?>(null);

  /// Pending client requests targeted at this scout (status `requested`),
  /// awaiting accept/decline. Drives the radar "incoming requests" indicator.
  final pendingRequests = <MissionEntity>[].obs;

  bool get hasPendingRequests => pendingRequests.isNotEmpty;
  int get pendingRequestCount => pendingRequests.length;

  /// Countdown string in HH:MM:SS format — counts down from 48 hrs.
  final countdown = '48:00:00'.obs;

  bool get hasActiveMission => activeMission.value != null;

  StreamSubscription<dynamic>? _missionsSub;
  StreamSubscription<dynamic>? _activeMissionSub;
  StreamSubscription<dynamic>? _requestsSub;
  Timer? _countdownTimer;

  final missionsBuilder = Key('MissionsBuilder');

  @override
  void onInit() {
    super.onInit();

    sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    // 1. Always start watching the active mission first.
    //    Nearby missions are only opened when no active mission is found.
    _watchActiveMission();

    // Watch incoming client requests independently of active/nearby state —
    // a scout can receive a direct request at any time.
    _watchRequests();

    // 2. When location becomes ready (or changes), start nearby stream —
    //    only if the scout has no active mission.
    ever(_locationService.error, (String? err) {
      if (err != null && !hasActiveMission) isLoading.value = false;
    });

    ever(_locationService.isReady, (bool ready) {
      if (ready && !hasActiveMission) _startNearbyStream();
    });

    ever(_locationService.position, (_) {
      if (_locationService.isReady.value && !hasActiveMission) {
        _startNearbyStream();
      }
    });
  }

  @override
  void onClose() {
    _missionsSub?.cancel();
    _activeMissionSub?.cancel();
    _requestsSub?.cancel();
    _stopCountdown();
    sweepController.dispose();
    super.onClose();
  }

  // ── Pending requests stream ───────────────────────────────────────────────
  void _watchRequests() {
    _requestsSub?.cancel();

    final lat = _locationService.latitude ?? 0;
    final lng = _locationService.longitude ?? 0;
    final user = Get.find<UserController>().currentUser.value;

    final profileId = user?.scoutProfile?.id;
    if (profileId == null) return;

    _requestsSub =
        _watchRequestsUseCase(
          WatchActiveMissionInput(
            scoutLat: lat,
            scoutLng: lng,
            profileId: profileId,
          ),
        ).listen(
          (response) {
            response.fold(
              (_) {}, // keep the last known list on transient errors
              (data) => pendingRequests.assignAll(data),
            );
          },
          onError: (_) {},
        );
  }

  // ── Active mission stream ─────────────────────────────────────────────────
  void _watchActiveMission() {
    _activeMissionSub?.cancel();

    final lat = _locationService.latitude ?? 0;
    final lng = _locationService.longitude ?? 0;
    final user = Get.find<UserController>().currentUser.value;

    _activeMissionSub =
        _watchActiveUseCase(
          WatchActiveMissionInput(
            scoutLat: lat,
            scoutLng: lng,
            profileId: user?.scoutProfile?.id,
          ),
        ).listen(
          (response) {
            response.fold(
              (_) {
                // On error watching active mission, fall through to nearby stream.
                if (!hasActiveMission && _locationService.isReady.value) {
                  _startNearbyStream();
                }
              },
              (data) {
                activeMission.value = data;

                if (data != null) {
                  // Lock radar — stop scanning for nearby missions.
                  _missionsSub?.cancel();
                  isLoading.value = false;
                  _startCountdown(data.acceptedAt);
                } else {
                  // No active mission — resume nearby scan.
                  _stopCountdown();
                  if (_locationService.isReady.value) _startNearbyStream();
                }

                update([missionsBuilder]);
              },
            );
          },
          onError: (_) {
            if (_locationService.isReady.value) _startNearbyStream();
          },
        );
  }

  // ── Nearby missions stream ────────────────────────────────────────────────
  void _startNearbyStream() {
    final lat = _locationService.latitude;
    final lng = _locationService.longitude;
    if (lat == null || lng == null) return;

    if (missions.isEmpty) isLoading.value = true;
    _missionsSub?.cancel();

    _missionsSub =
        _watchNearbyUseCase(
          NearbyMissionsInput(lat: lat, lng: lng, radiusMeters: 500000),
        ).listen(
          (response) {
            response.fold(
              (error) => Toast.error(error.message),
              (data) => missions = data,
            );
            isLoading.value = false;
            update([missionsBuilder]);
          },
          onError: (_) {
            isLoading.value = false;
            Toast.error('Failed to load missions. Kindly retry.');
          },
        );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> acceptMission(String missionId) async {
    isAccepting.value = true;

    final result = await _acceptUseCase(
      AcceptMissionInput(missionId: missionId),
    );

    result.fold(
      (err) => Toast.error(err.message),
      (_) => Get.back(), // close MissionDetailsPage
    );

    isAccepting.value = false;
  }

  Future<void> completeMission() async {
    return Get.toNamed(
      MissionDetailsPage.route,
      arguments: activeMission.value,
    );
  }

  /// Open the full details/review screen for a pending request.
  void openRequest(MissionEntity request) {
    Get.toNamed(MissionDetailsPage.route, arguments: request);
  }

  /// Id of the request currently being declined — drives the per-card spinner.
  final decliningRequestId = RxnString();

  /// Decline a pending client request. The realtime stream removes it from
  /// [pendingRequests] automatically once the status changes.
  Future<void> declineRequest(String missionId) async {
    decliningRequestId.value = missionId;

    final result = await _declineMissionUseCase(
      DeclineMissionInput(
        missionId: missionId,
        status: MissionStatus.cancelled,
      ),
    );

    result.fold(
      (err) => Toast.error(err.message),
      (_) => Toast.success('Request declined'),
    );

    decliningRequestId.value = null;
  }

  Future<void> abandonMission() async {
    final mission = activeMission.value;
    if (mission?.id == null) return;

    isUpdatingStatus.value = true;

    final result = await _declineMissionUseCase(
      DeclineMissionInput(
        missionId: mission!.id!,
        status: MissionStatus.cancelled,
      ),
    );

    result.fold((err) => Toast.error(err.message), (_) {
      // activeMission stream will clear state automatically.
    });

    isUpdatingStatus.value = false;
  }

  // ── Countdown ─────────────────────────────────────────────────────────────

  void _startCountdown(String? acceptedAtStr) {
    _stopCountdown();

    final base = acceptedAtStr != null
        ? (DateTime.tryParse(acceptedAtStr)?.toUtc() ?? DateTime.now().toUtc())
        : DateTime.now().toUtc();

    final expiry = base.add(const Duration(hours: 48));

    _tickCountdown(expiry);
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickCountdown(expiry),
    );
  }

  void _tickCountdown(DateTime expiry) {
    final remaining = expiry.difference(DateTime.now().toUtc());

    if (remaining.isNegative) {
      countdown.value = '00:00:00';
      _stopCountdown();
      // Mission window expired on the client side — clear local state.
      // activeMission.value = null;
      update([missionsBuilder]);
      if (_locationService.isReady.value) _startNearbyStream();
      return;
    }

    final h = remaining.inHours.toString().padLeft(2, '0');
    final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    countdown.value = '$h:$m:$s';
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }
}
