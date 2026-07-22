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
    // The created MissionEntity is passed as a GetX argument from
    // PostMissionController after a successful insert.
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

  // ── No-scouts timeout ─────────────────────────────────────────────────────

  /// Starts the 20-second window. If at least one scout is revealed before it
  /// fires, [_cancelNoScoutsTimer] suppresses it.
  void _startNoScoutsTimer() {
    _noScoutsTimer = Timer(_noScoutsTimeout, _onNoScoutsTimeout);
  }

  /// Suppresses the fallback — called only when real scouts are being revealed
  /// or when a scout accepts the mission so the redirect doesn't interfere.
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

  // ── Progressive reveal (keeps the Uber-radar feel with real data) ─────────

  void _revealProgressively(List<NearbyScout> nearbyScouts) {
    // Only suppress the timeout when there are real scouts to show.
    // An empty response leaves the timer running so the 20 s fallback fires.
    if (nearbyScouts.isEmpty) return;

    _cancelNoScoutsTimer();

    // Animate the "X SCOUTS NOTIFIED" counter to ~8× the actual count,
    // capped at 50, to give a sense of broadcast reach.
    final notifyTarget = (nearbyScouts.length * 8).clamp(1, 50);
    _notifyTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (scoutsNotified.value >= notifyTarget) {
        t.cancel();
        return;
      }
      scoutsNotified.value = min(
        scoutsNotified.value + Random().nextInt(4) + 1,
        notifyTarget,
      );
    });

    // Reveal each scout card one-by-one with a stagger so the radar dots
    // appear progressively rather than all at once.
    int index = 0;
    _revealTimer = Timer.periodic(const Duration(milliseconds: 1800), (t) {
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

  /// Converts a [NearbyScout] into a normalised radar position.
  ///
  /// Uses the golden-angle spread so multiple scouts never overlap on the
  /// radar, and maps their real distance to the radar radius band [0.25–0.85].
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
