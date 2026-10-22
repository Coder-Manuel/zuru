import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/core/services/analytics_service/analytics_service.dart';
import 'package:zuru/core/services/analytics_service/static/event_enum.dart';
import 'package:zuru/core/services/fx_service/fx_service.dart';
import 'package:zuru/core/services/location_service/location_service.dart';
import 'package:zuru/core/services/storage_service/storage.service.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/entities/mission_page.entity.dart';
import 'package:zuru/modules/missions/domain/usecases/accept_mission.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/decline_mission.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/search_missions.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/watch_active_mission.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/watch_mission_pool.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/watch_scout_requests.usecase.dart';
import 'package:zuru/modules/missions/presentation/pages/mission_details_page.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

class RadarController extends GetxController
    with GetSingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// How far the radar looks for live checks.
  static const radiusMeters = 60000.0;

  /// Markers drawn on the radar — the nearest ones; the rest show as "+N".
  static const mapLimit = 30;

  /// Cards previewed in the panel under the radar.
  static const previewLimit = 3;

  /// The pool is re-queried once the scout has moved this far.
  static const requeryDistanceMeters = 1000.0;

  final _searchUseCase = Get.find<SearchMissionsUseCase>();
  final _watchPoolUseCase = Get.find<WatchMissionPoolUseCase>();
  final _watchActiveUseCase = Get.find<WatchActiveMissionUseCase>();
  final _watchRequestsUseCase = Get.find<WatchScoutRequestsUseCase>();
  final _acceptUseCase = Get.find<AcceptMissionUseCase>();
  final _declineMissionUseCase = Get.find<DeclineMissionUseCase>();
  final _locationService = Get.find<LocationService>();
  final _fx = Get.find<FxService>();

  late final AnimationController sweepController;

  /// The nearest pool missions within [radiusMeters] — the radar markers.
  /// Always nearest-first; the scout's [sort] never changes the map.
  List<MissionEntity> missions = <MissionEntity>[];

  /// The first [previewLimit] missions in the scout's [sort].
  List<MissionEntity> preview = <MissionEntity>[];

  /// Every pool mission within [radiusMeters], shown or not.
  int totalCount = 0;

  /// The scout's chosen order for the preview and the Live Checks page.
  final sort = MissionSort.nearest.obs;

  /// Pool changes within range, for the Live Checks page. The radar owns the
  /// one `mission_pool` subscription.
  Stream<MissionPoolEvent> get poolEvents => _poolEvents.stream;
  final _poolEvents = StreamController<MissionPoolEvent>.broadcast();
  final isLoading = true.obs;
  final isAccepting = false.obs;
  final isUpdatingStatus = false.obs;

  /// The scout's currently accepted mission. Null when none is active.
  final activeMission = Rx<MissionEntity?>(null);

  final pendingRequests = <MissionEntity>[].obs;

  bool get hasPendingRequests => pendingRequests.isNotEmpty;
  int get pendingRequestCount => pendingRequests.length;

  /// Countdown string in HH:MM:SS format — counts down from 5 hrs.
  final countdown = '05:00:00'.obs;

  /// MM:SS the client has left to pay for an accepted live request before it
  /// is released. '--:--' when the deadline is unknown.
  final paymentCountdown = '--:--'.obs;

  bool get hasActiveMission => activeMission.value != null;

  /// True while the accepted live check is still unpaid — the guide holds it
  /// but can't start until the client's payment lands.
  bool get isAwaitingPayment =>
      activeMission.value?.awaitingClientPayment ?? false;

  Rx<String?> get locationError => _locationService.error;
  bool get hasLocationError => _locationService.error.value != null;

  /// True when the device's location services are switched off entirely.
  bool get isLocationServiceDisabled =>
      _locationService.error.value?.contains('services are disabled') ?? false;

  bool get isLocationPermanentlyDenied =>
      _locationService.error.value?.contains('permanently denied') ?? false;

  bool get isResolvingLocation =>
      !_locationService.isReady.value && _locationService.error.value == null;

  bool get showLoading => isLoading.value || isResolvingLocation;

  Future<void> retryLocation() async {
    isLoading.value = true;
    await _locationService.retryInit();
  }

  Future<void> openLocationSettings() =>
      _locationService.openLocationSettings();
  Future<void> openAppSettings() => _locationService.openAppSettings();

  StreamSubscription<dynamic>? _poolSub;
  StreamSubscription<dynamic>? _activeMissionSub;
  StreamSubscription<dynamic>? _requestsSub;
  Timer? _countdownTimer;
  Timer? _paymentTimer;
  Timer? _poolRefreshTimer;

  /// Where the pool was last queried from.
  ({double lat, double lng})? _lastOrigin;

  /// Bumped per query so a slow, superseded response is dropped. The preview
  /// has its own counter so a sort change never discards the map's result.
  int _poolQueryId = 0;
  int _previewQueryId = 0;
  final _random = Random();

  final missionsBuilder = Key('MissionsBuilder');

  @override
  void onInit() {
    super.onInit();

    sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    WidgetsBinding.instance.addObserver(this);
    _restoreSort();

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
      if (ready && !hasActiveMission) _startPool();
    });

    // Position ticks every few metres; only a real move re-queries the pool.
    ever(_locationService.position, (_) {
      if (_locationService.isReady.value &&
          !hasActiveMission &&
          _movedSinceLastQuery) {
        _startPool();
      }
    });

    if (_locationService.isReady.value) {
      if (!hasActiveMission) _startPool();
    } else {
      _locationService.ensureInitialized();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No pushes while backgrounded; catch up once on return.
    if (state == AppLifecycleState.paused) {
      _stopPool();
    } else if (state == AppLifecycleState.resumed) {
      if (_locationService.isReady.value && !hasActiveMission) _startPool();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPool();
    _poolEvents.close();
    _activeMissionSub?.cancel();
    _requestsSub?.cancel();
    _stopCountdown();
    _stopPaymentCountdown();
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
        ).listen((response) {
          response.fold(
            (_) {}, // keep the last known list on transient errors
            (data) => pendingRequests.assignAll(data),
          );
        }, onError: (_) {});
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
                // On error watching active mission, fall through to the pool.
                if (!hasActiveMission && _locationService.isReady.value) {
                  _startPool();
                }
              },
              (data) {
                activeMission.value = data;

                if (data != null) {
                  // Lock radar — stop scanning for nearby missions.
                  _stopPool();
                  isLoading.value = false;
                  _startCountdown(data.acceptedAt);
                  if (data.awaitingClientPayment) {
                    _startPaymentCountdown(data);
                  } else {
                    _stopPaymentCountdown();
                  }
                } else {
                  // No active mission — resume nearby scan.
                  _stopCountdown();
                  _stopPaymentCountdown();
                  if (_locationService.isReady.value) _startPool();
                }

                update([missionsBuilder]);
              },
            );
          },
          onError: (_) {
            if (_locationService.isReady.value) _startPool();
          },
        );
  }

  // ── Mission pool ──────────────────────────────────────────────────────────
  //
  // Three small reads instead of one big stream: the nearest [mapLimit] for
  // the radar, the first [previewLimit] in the scout's [sort] for the panel,
  // and pushed pool events that patch both in place. A full re-query only
  // happens on a real move, on resume, or when an event needs a backfill.

  bool get _movedSinceLastQuery {
    final origin = _lastOrigin;
    if (origin == null) return true;
    final moved = _locationService.distanceTo(origin.lat, origin.lng);
    return moved == null || moved >= requeryDistanceMeters;
  }

  void _startPool() {
    _watchPool();
    _refreshPool();
  }

  void _stopPool() {
    _poolSub?.cancel();
    _poolSub = null;
    _poolRefreshTimer?.cancel();
    _poolRefreshTimer = null;
  }

  void _watchPool() {
    if (_poolSub != null) return;
    _poolSub = _watchPoolUseCase().listen(
      (response) => response.fold((_) {}, _onPoolEvent),
      onError: (_) {},
      // Lets the next start re-subscribe after the channel drops.
      onDone: () => _poolSub = null,
    );
  }

  Future<void> _refreshPool() async {
    final lat = _locationService.latitude;
    final lng = _locationService.longitude;
    if (lat == null || lng == null) return;

    _lastOrigin = (lat: lat, lng: lng);
    _poolRefreshTimer?.cancel();
    final queryId = ++_poolQueryId;
    final previewQueryId = ++_previewQueryId;
    if (missions.isEmpty) isLoading.value = true;

    final currentSort = sort.value;
    final results = await Future.wait([
      _searchUseCase(SearchMissionsInput(lat: lat, lng: lng, limit: mapLimit)),
      if (currentSort != MissionSort.nearest)
        _searchUseCase(_previewInput(lat, lng, currentSort)),
    ]);
    if (queryId != _poolQueryId) return;

    results.first.fold((error) => Toast.error(error.message), (page) {
      missions = page.missions;
      totalCount = page.totalCount;
    });
    if (previewQueryId == _previewQueryId) {
      if (currentSort == MissionSort.nearest) {
        preview = missions.take(previewLimit).toList();
      } else {
        results.last.fold((_) {}, (page) => preview = page.missions);
      }
    }

    isLoading.value = false;
    update([missionsBuilder]);
  }

  /// Re-reads only the panel preview, after the scout changes [sort].
  Future<void> _refreshPreview() async {
    final currentSort = sort.value;
    if (currentSort == MissionSort.nearest) {
      preview = missions.take(previewLimit).toList();
      update([missionsBuilder]);
      return;
    }

    final origin = _lastOrigin;
    if (origin == null) return;
    final queryId = ++_previewQueryId;
    final RepoResponse<MissionPage> result = await _searchUseCase(
      _previewInput(origin.lat, origin.lng, currentSort),
    );
    if (queryId != _previewQueryId) return;

    result.fold(
      (error) => Toast.error(error.message),
      (page) => preview = page.missions,
    );
    update([missionsBuilder]);
  }

  SearchMissionsInput _previewInput(double lat, double lng, MissionSort by) =>
      SearchMissionsInput(
        lat: lat,
        lng: lng,
        sort: by,
        limit: previewLimit,
        usdToKes: _fx.usdToKes.value,
      );

  /// Coalesces a burst of pool events into one re-query, staggered by a
  /// random 1–3 s so every scout doesn't hit the backend at once.
  void _schedulePoolRefresh() {
    if (_poolRefreshTimer?.isActive ?? false) return;
    _poolRefreshTimer = Timer(
      Duration(milliseconds: 1000 + _random.nextInt(2000)),
      _refreshPool,
    );
  }

  bool _isWithinRange(MissionPoolEvent event) {
    final lat = event.latitude;
    final lng = event.longitude;
    if (lat == null || lng == null) return true;
    final distance = _locationService.distanceTo(lat, lng);
    return distance == null || distance <= radiusMeters;
  }

  void _onPoolEvent(MissionPoolEvent event) {
    if (hasActiveMission) return;

    final isShown =
        missions.any((m) => m.id == event.id) ||
        preview.any((m) => m.id == event.id);
    if (!isShown && !_isWithinRange(event)) return;

    _poolEvents.add(event);

    switch (event.type) {
      case MissionPoolEventType.removed:
        missions = missions.where((m) => m.id != event.id).toList();
        preview = preview.where((m) => m.id != event.id).toList();
        totalCount = max(0, totalCount - 1);
        update([missionsBuilder]);

        // Only re-query when something hidden can take the freed slot.
        final previewFull = preview.length >= min(previewLimit, totalCount);
        if (totalCount > missions.length || !previewFull) {
          _schedulePoolRefresh();
        }
      case MissionPoolEventType.added:
        _schedulePoolRefresh();
      case MissionPoolEventType.updated:
        if (isShown) _schedulePoolRefresh();
    }
  }

  // ── Sort ──────────────────────────────────────────────────────────────────

  Future<void> setSort(MissionSort value, {String source = 'radar'}) async {
    if (sort.value == value) return;
    sort.value = value;

    _guard(
      () => StorageService.save(StorageKeys.missionSortKey, value: value.name),
    );
    _guard(
      () => AnalyticsService.instance.trackEvent(
        event: AnalyticsEvent.MISSION_SORT_CHANGED,
        properties: {'sort': value.name, 'source': source},
      ),
    );

    await _refreshPreview();
  }

  Future<void> _restoreSort() async {
    try {
      final saved = await StorageService.get<String>(
        StorageKeys.missionSortKey,
      );
      final restored = MissionSort.fromName(saved);
      if (restored == sort.value) return;
      sort.value = restored;
      if (_lastOrigin != null) await _refreshPreview();
    } catch (_) {
      // Keep the default order when storage isn't available.
    }
  }

  /// Fire-and-forget for side effects that must never break the radar.
  void _guard(Future<void> Function() run) {
    try {
      unawaited(run().catchError((_) {}));
    } catch (_) {}
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> acceptMission(MissionEntity mission) async {
    final missionId = mission.id;
    if (missionId == null) return;

    isAccepting.value = true;

    final result = await _acceptUseCase(
      AcceptMissionInput(missionId: missionId),
    );

    result.fold((err) => Toast.error(err.message), (_) {
      Get.back(); // close MissionDetailsPage
      // A live request is only paid for after acceptance — say so, otherwise
      // the guide is left wondering why they can't set off.
      if (mission.isLiveRequest && !mission.isPublished) {
        Toast.success('Accepted — waiting for the client to pay');
      }
    });

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
  Future<void> declineRequest(MissionEntity mission) async {
    decliningRequestId.value = mission.id;

    final result = await _declineMissionUseCase(
      DeclineMissionInput(mission: mission),
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
      DeclineMissionInput(mission: mission!),
    );

    // activeMission stream clears local state once the status changes.
    result.fold(
      (err) => Toast.error(err.message),
      (outcome) => Toast.success(switch (outcome) {
        DeclineOutcome.declined => 'Live request declined',
        DeclineOutcome.released => 'Live check released back to the board',
      }),
    );

    isUpdatingStatus.value = false;
  }

  // ── Countdown ─────────────────────────────────────────────────────────────

  void _startCountdown(String? acceptedAtStr) {
    _stopCountdown();

    final base = acceptedAtStr != null
        ? (DateTime.tryParse(acceptedAtStr)?.toUtc() ?? DateTime.now().toUtc())
        : DateTime.now().toUtc();

    final expiry = base.add(const Duration(hours: 5));

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
      if (_locationService.isReady.value) _startPool();
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

  // ── Payment countdown ─────────────────────────────────────────────────────

  /// Ticks down the client's payment window. When it runs out the backend
  /// releases the request; the active-mission stream then clears local state.
  void _startPaymentCountdown(MissionEntity mission) {
    _stopPaymentCountdown();
    _tickPaymentCountdown(mission);
    _paymentTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickPaymentCountdown(mission),
    );
  }

  void _tickPaymentCountdown(MissionEntity mission) {
    final left = mission.paymentTimeLeft;
    if (left == null) {
      paymentCountdown.value = '--:--';
      _stopPaymentCountdown();
      return;
    }

    final m = left.inMinutes.toString().padLeft(2, '0');
    final s = (left.inSeconds % 60).toString().padLeft(2, '0');
    paymentCountdown.value = '$m:$s';

    if (left == Duration.zero) _stopPaymentCountdown();
  }

  void _stopPaymentCountdown() {
    _paymentTimer?.cancel();
    _paymentTimer = null;
    paymentCountdown.value = '--:--';
  }
}
