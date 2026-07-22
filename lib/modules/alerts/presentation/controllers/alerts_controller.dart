import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:zuru/modules/alerts/data/models/alert.model.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/usecases/watch_scout_requests.usecase.dart';
import 'package:zuru/modules/missions/presentation/pages/mission_details_page.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

class AlertsController extends GetxController {
  final _watchRequestsUseCase = Get.find<WatchScoutRequestsUseCase>();
  final _userController = Get.find<UserController>();

  static const _container = 'zuru_alerts';

  /// Feed, newest first.
  final RxList<AlertModel> alerts = <AlertModel>[].obs;
  final RxBool isReady = false.obs;

  int get unreadCount => alerts.where((a) => !a.isRead).length;
  bool get hasUnread => unreadCount > 0;

  GetStorage? _box;
  StreamSubscription<dynamic>? _requestsSub;

  /// Live missions behind still-pending request alerts, keyed by mission id —
  /// lets a tap deep-link into mission details while the request is open.
  final Map<String, MissionEntity> _liveMissions = {};

  String? get _profileId => _userController.currentUser.value?.scoutProfile?.id;
  String get _storageKey => 'alerts_${_userController.currentUser.value?.id}';

  @override
  void onInit() {
    super.onInit();
    _bootstrap();

    // (Re)subscribe whenever the signed-in user resolves or changes — mirrors
    // how RadarController defers work until the scout profile is available.
    ever(_userController.currentUser, (_) {
      _loadPersisted();
      _subscribe();
    });
  }

  @override
  void onClose() {
    _requestsSub?.cancel();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    await GetStorage.init(_container);
    _box = GetStorage(_container);
    isReady.value = true;
    _loadPersisted();
    _subscribe();
  }

  // ── Persistence ─────────────────────────────────────────────────────────────

  void _loadPersisted() {
    final box = _box;
    if (box == null || _profileId == null) return;

    final raw = box.read<List<dynamic>>(_storageKey) ?? const [];
    final loaded = raw
        .whereType<Map>()
        .map((e) => AlertModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    _sortAndAssign(loaded);
  }

  void _persist() {
    final box = _box;
    if (box == null || _profileId == null) return;
    box.write(_storageKey, alerts.map((a) => a.toJson()).toList());
  }

  void _sortAndAssign(List<AlertModel> list) {
    list.sort((a, b) {
      final da = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(0);
      final db = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(0);
      return db.compareTo(da);
    });
    alerts.assignAll(list);
  }

  // ── Ingest ──────────────────────────────────────────────────────────────────

  void _subscribe() {
    _requestsSub?.cancel();
    final profileId = _profileId;
    if (profileId == null) return;

    _requestsSub =
        _watchRequestsUseCase(
          WatchActiveMissionInput(profileId: profileId),
        ).listen((response) {
          response.fold(
            (_) {}, // keep last known feed on transient errors
            _ingestRequests,
          );
        }, onError: (_) {});
  }

  void _ingestRequests(List<MissionEntity> requests) {
    if (_box == null) return;

    final existingIds = alerts.map((a) => a.id).toSet();
    var changed = false;

    for (final mission in requests) {
      if (mission.id == null) continue;
      _liveMissions[mission.id!] = mission;

      final alert = AlertModel.liveRequest(mission);
      if (existingIds.contains(alert.id)) continue; // dedup on re-emission

      alerts.add(alert);
      existingIds.add(alert.id);
      changed = true;
    }

    if (changed) {
      _sortAndAssign(alerts.toList());
      _persist();
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void markAllRead() {
    if (!hasUnread) return;
    alerts.assignAll(alerts.map((a) => a.copyWith(isRead: true)).toList());
    _persist();
  }

  void _markRead(AlertModel alert) {
    final idx = alerts.indexWhere((a) => a.id == alert.id);
    if (idx == -1 || alerts[idx].isRead) return;
    alerts[idx] = alerts[idx].copyWith(isRead: true);
    alerts.refresh();
    _persist();
  }

  void onTapAlert(AlertModel alert) {
    _markRead(alert);

    // Deep-link into the mission while the request is still open. Once it's been
    // accepted/declined the mission drops out of the live map and the alert
    // simply stands as a history entry.
    final mission = alert.missionId != null
        ? _liveMissions[alert.missionId]
        : null;
    if (mission != null) {
      Get.toNamed(MissionDetailsPage.route, arguments: mission);
    }
  }

  void clearAll() {
    alerts.clear();
    _liveMissions.clear();
    _persist();
  }
}
