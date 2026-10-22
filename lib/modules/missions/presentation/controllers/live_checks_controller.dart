import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:zuru/core/services/analytics_service/analytics_service.dart';
import 'package:zuru/core/services/analytics_service/static/event_enum.dart';
import 'package:zuru/core/services/fx_service/fx_service.dart';
import 'package:zuru/core/services/location_service/location_service.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/entities/mission_page.entity.dart';
import 'package:zuru/modules/missions/domain/usecases/search_missions.usecase.dart';
import 'package:zuru/modules/missions/presentation/controllers/radar_controller.dart';

/// The full, sorted live-check list behind the radar's "See all".
///
/// The scout's position and the USD → KES rate are pinned when the list
/// loads, so every page is ordered the same way; pull-to-refresh re-pins them.
/// Pool changes arrive through [RadarController.poolEvents]: removals are
/// applied in place, while additions and edits only raise [hasUpdates] so the
/// list never reshuffles under the scout's thumb.
class LiveChecksController extends GetxController with WidgetsBindingObserver {
  static const pageSize = 20;

  final SearchMissionsUseCase _searchUseCase;
  final LocationService _locationService;
  final FxService _fx;
  final RadarController _radar;

  LiveChecksController({
    SearchMissionsUseCase? searchUseCase,
    LocationService? locationService,
    FxService? fx,
    RadarController? radar,
  }) : _searchUseCase = searchUseCase ?? Get.find<SearchMissionsUseCase>(),
       _locationService = locationService ?? Get.find<LocationService>(),
       _fx = fx ?? Get.find<FxService>(),
       _radar = radar ?? Get.find<RadarController>();

  final missions = <MissionEntity>[].obs;
  final totalCount = 0.obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final error = RxnString();

  /// Live checks published since the list loaded.
  final newCount = 0.obs;

  /// A listed live check changed, or the app was away, since the list loaded.
  final isStale = false.obs;

  Rx<MissionSort> get sort => _radar.sort;
  bool get hasMore => _cursor != null;
  bool get hasUpdates => newCount.value > 0 || isStale.value;

  MissionPageCursor? _cursor;
  ({double lat, double lng, double usdToKes})? _pinned;
  int _queryId = 0;
  StreamSubscription<MissionPoolEvent>? _poolSub;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _poolSub = _radar.poolEvents.listen(_onPoolEvent);
    try {
      unawaited(
        AnalyticsService.instance
            .trackEvent(
              event: AnalyticsEvent.LIVE_CHECKS_OPENED,
              properties: {'sort': sort.value.name},
            )
            .catchError((_) {}),
      );
    } catch (_) {}
    reload();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _poolSub?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pool events stop while backgrounded, so the list may have drifted.
    if (state == AppLifecycleState.resumed) isStale.value = true;
  }

  /// Loads the first page from the scout's current position.
  Future<void> reload() async {
    final lat = _locationService.latitude;
    final lng = _locationService.longitude;
    if (lat == null || lng == null) {
      error.value = 'We need your location to list live checks.';
      isLoading.value = false;
      return;
    }

    _pinned = (lat: lat, lng: lng, usdToKes: _fx.usdToKes.value);
    _cursor = null;
    newCount.value = 0;
    isStale.value = false;
    isLoadingMore.value = false;
    if (missions.isEmpty) isLoading.value = true;

    final queryId = ++_queryId;
    final result = await _searchUseCase(_input());
    if (queryId != _queryId) return;

    result.fold((fail) => error.value = fail.message, (page) {
      error.value = null;
      missions.assignAll(page.missions);
      totalCount.value = page.totalCount;
      _cursor = page.nextCursor;
    });
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    final cursor = _cursor;
    if (cursor == null || isLoading.value || isLoadingMore.value) return;

    isLoadingMore.value = true;
    final queryId = _queryId;
    final result = await _searchUseCase(_input(cursor: cursor));
    if (queryId != _queryId) return;

    result.fold((fail) => Toast.error(fail.message), (page) {
      // A mission can shift pages between reads; never list it twice.
      final listed = missions.map((m) => m.id).toSet();
      missions.addAll(page.missions.where((m) => !listed.contains(m.id)));
      totalCount.value = page.totalCount;
      _cursor = page.nextCursor;
    });
    isLoadingMore.value = false;
  }

  Future<void> setSort(MissionSort value) async {
    if (sort.value == value) return;
    missions.clear();
    unawaited(_radar.setSort(value, source: 'live_checks'));
    await reload();
  }

  SearchMissionsInput _input({MissionPageCursor? cursor}) {
    final pinned = _pinned!;
    return SearchMissionsInput(
      lat: pinned.lat,
      lng: pinned.lng,
      sort: sort.value,
      limit: pageSize,
      cursor: cursor,
      usdToKes: pinned.usdToKes,
    );
  }

  void _onPoolEvent(MissionPoolEvent event) {
    final isListed = missions.any((m) => m.id == event.id);
    switch (event.type) {
      case MissionPoolEventType.removed:
        if (isListed) missions.removeWhere((m) => m.id == event.id);
        totalCount.value = max(0, totalCount.value - 1);
      case MissionPoolEventType.added:
        newCount.value++;
      case MissionPoolEventType.updated:
        if (isListed) isStale.value = true;
    }
  }
}
