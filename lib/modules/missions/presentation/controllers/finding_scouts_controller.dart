import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/entities/nearby_scout.entity.dart';
import 'package:zuru/modules/missions/domain/usecases/get_nearby_scouts.usecase.dart';

class FindingScoutsController extends GetxController {
  final _getNearbyScoutsUseCase = Get.find<GetNearbyScoutsUseCase>();
  final _supabase = Get.find<SupabaseClient>();

  // ── Timeout constants ─────────────────────────────────────────────────────

  /// How long to wait for scouts before showing the no-scouts fallback UI.
  static const _noScoutsTimeout = Duration(seconds: 10);

  /// How long the redirect countdown lasts before going back to home.
  static const _redirectCountdownStart = 6;

  // ── State ─────────────────────────────────────────────────────────────────
  final RxInt scoutsNotified = 0.obs;
  final RxList<NearbyScout> scouts = <NearbyScout>[].obs;
  final RxList<RadarDot> radarDots = <RadarDot>[].obs;
  final RxBool isLoading = true.obs;

  /// True once the 20 s window expires without any scout being revealed.
  final RxBool showNoScoutsFallback = false.obs;

  /// Countdown (seconds) shown in the fallback UI before redirecting to home.
  final RxInt redirectCountdown = _redirectCountdownStart.obs;

  // ── Private ───────────────────────────────────────────────────────────────
  late final MissionEntity _mission;
  StreamSubscription? _missionSubscription;
  Timer? _notifyTimer;
  Timer? _revealTimer;

  /// Fires after [_noScoutsTimeout] if no scouts have appeared.
  Timer? _noScoutsTimer;

  /// Ticks every second while the fallback countdown is running.
  Timer? _redirectTimer;

  // ── Init ──────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _mission = Get.arguments as MissionEntity;
    _fetchNearbyScouts();
    _watchMissionAcceptance();
    _startNoScoutsTimer();
  }

  // ── Fetch nearby scouts (one-time snapshot) ───────────────────────────────

  Future<void> _fetchNearbyScouts() async {
    isLoading.value = true;

    final response = await _getNearbyScoutsUseCase(
      NearbyScoutsInput(
        latitude: _mission.latitude ?? 0,
        longitude: _mission.longitude ?? 0,
        radiusKm: 80,
      ),
    );

    isLoading.value = false;

    response.fold((error) => Toast.error(error.message), _revealProgressively);
  }

  void _startNoScoutsTimer() {
    _noScoutsTimer = Timer(_noScoutsTimeout, _onNoScoutsTimeout);
  }

  void _cancelNoScoutsTimer() {
    _noScoutsTimer?.cancel();
    _noScoutsTimer = null;
  }

  void _onNoScoutsTimeout() {
    if (scouts.isNotEmpty) return; // scouts arrived just in time — do nothing
    showNoScoutsFallback.value = true;
    redirectCountdown.value = _redirectCountdownStart;
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (redirectCountdown.value <= 1) {
        t.cancel();
        Get.until((route) => route.isFirst);
      } else {
        redirectCountdown.value--;
      }
    });
  }

  void _revealProgressively(List<NearbyScout> nearbyScouts) {
    if (nearbyScouts.isEmpty) return;

    _cancelNoScoutsTimer();

    final notifyTarget = nearbyScouts.length;
    _notifyTimer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (scoutsNotified.value >= notifyTarget) {
        t.cancel();
        return;
      }
      scoutsNotified.value = min(scoutsNotified.value + 1, notifyTarget);
    });

    int index = 0;
    _revealTimer = Timer.periodic(const Duration(milliseconds: 350), (t) {
      if (index >= nearbyScouts.length) {
        t.cancel();
        return;
      }
      final scout = nearbyScouts[index];
      scouts.add(scout);
      radarDots.add(_radarDotFor(scout, index));
      index++;
    });
  }

  RadarDot _radarDotFor(NearbyScout scout, int index) {
    const maxDistanceM = 5000.0; // matches the 5 km RPC radius
    final r =
        0.25 + (scout.distanceMeters / maxDistanceM).clamp(0.0, 1.0) * 0.60;
    final angleRad = (index * 137.508) * (pi / 180); // golden angle ≈ 137.5°
    return RadarDot(
      x: (r * cos(angleRad)).clamp(-0.9, 0.9),
      y: (r * sin(angleRad)).clamp(-0.9, 0.9),
    );
  }

  // ── Realtime — watch for mission acceptance ────────────────────────────────
  //
  // We do NOT stream the scout list — the RPC is a point-in-time snapshot and
  // can't be subscribed to. What matters in real-time is whether a scout has
  // accepted THIS mission so we can navigate the client forward.

  void _watchMissionAcceptance() {
    final missionId = _mission.id;
    if (missionId == null) return;

    _missionSubscription = _supabase
        .from('missions')
        .stream(primaryKey: ['id'])
        .eq('id', missionId)
        .listen((rows) {
          if (rows.isEmpty) return;
          final status = rows.first['status'] as String?;
          if (status == MissionStatus.accepted.name) {
            _missionSubscription?.cancel();
            // Cancel any in-progress redirect so it doesn't fight navigation.
            _cancelNoScoutsTimer();
            _redirectTimer?.cancel();
            // TODO: navigate to the mission-tracker screen once it exists.
            // Get.offNamed(MissionTrackerPage.route, arguments: _mission);
            Toast.success('A guide has accepted your live check! 🎉');
          }
        });
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  @override
  void onClose() {
    _notifyTimer?.cancel();
    _revealTimer?.cancel();
    _noScoutsTimer?.cancel();
    _redirectTimer?.cancel();
    _missionSubscription?.cancel();
    super.onClose();
  }
}

// ── Radar dot position ────────────────────────────────────────────────────────

class RadarDot {
  final double x;
  final double y;
  const RadarDot({required this.x, required this.y});
}
