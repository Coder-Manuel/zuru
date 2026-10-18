import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/routes/app_routes.dart';
import 'package:zuru/core/services/notification_service/notification_service.dart';
import 'package:zuru/core/services/role_service/role_service.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/home/presentation/controllers/home_controller.dart';
import 'package:zuru/modules/home/presentation/controllers/maps_tab_controller.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/entities/session.entity.dart';
import 'package:zuru/modules/missions/domain/usecases/get_mission_by_id.usecase.dart';
import 'package:zuru/modules/notifications/data/models/notification_payload.dart';
import 'package:zuru/modules/notifications/data/models/notification_type.dart';
import 'package:zuru/modules/notifications/domain/usecases/mark_notification_read.usecase.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

/// Turns a notification into navigation. Taps that arrive before the user has
/// reached home (cold start) wait until they do.
class NotificationRouter extends GetxService {
  static NotificationRouter get instance => Get.find<NotificationRouter>();

  final _getMissionById = Get.find<GetMissionByIdUseCase>();
  final _markRead = Get.find<MarkNotificationReadUseCase>();

  NotificationPayload? _pending;
  bool _homeReached = false;

  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  @override
  void onInit() {
    super.onInit();
    _openedSub = NotificationService.openedMessages.listen(_openMessage);
    _foregroundSub = NotificationService.foregroundMessages.listen(
      _onForeground,
    );
  }

  @override
  Future<void> onReady() async {
    super.onReady();
    final launch = await NotificationService.initialMessage();
    if (launch != null) _openMessage(launch);
  }

  @override
  void onClose() {
    _openedSub?.cancel();
    _foregroundSub?.cancel();
    super.onClose();
  }

  /// `GetMaterialApp.routingCallback`.
  void onRouteChanged(Routing? routing) {
    final route = routing?.current;
    if (route == null) return;

    if (_isHome(route)) {
      _homeReached = true;
      final pending = _pending;
      _pending = null;
      if (pending != null) open(pending);
    } else if (_signedOutRoutes.contains(route)) {
      _homeReached = false;
      _pending = null;
    }
  }

  Future<void> open(NotificationPayload payload) async {
    if (!_homeReached || Get.find<UserController>().currentUser.value == null) {
      _pending = payload;
      return;
    }

    final id = payload.notificationId;
    if (id != null) unawaited(_markRead(id));

    if (Get.currentRoute == AppRoutes.stream) {
      Toast.info(payload.body ?? 'Open it once your live ends.');
      return;
    }

    if (payload.type.role != RoleService.instance.role.value) {
      if (!await _confirmSwitch(payload.type.role)) return;
      if (!await Get.find<UserController>().switchTo(payload.type.role)) {
        return;
      }
      await WidgetsBinding.instance.endOfFrame;
    }

    await _perform(payload);
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _perform(NotificationPayload payload) async {
    switch (payload.type.action) {
      case NotificationAction.radar || NotificationAction.map:
        await _openTab(0);
      case NotificationAction.tasks || NotificationAction.liveChecks:
        await _openTab(1);
      case NotificationAction.payForMission:
        await _openTab(0);
        await _promptPayment(payload.missionId);
      case NotificationAction.joinLive:
        await _joinLive(payload.missionId);
    }
  }

  Future<void> _openTab(int index) async {
    Get.find<HomeController>().changePage(index);
    if (_isHome(Get.currentRoute)) return;

    Get.until((route) => route.isFirst || _isHome(route.settings.name));
    if (!_isHome(Get.currentRoute)) {
      await Get.offAllNamed(AppRoutes.home);
    }
  }

  Future<void> _promptPayment(String? missionId) async {
    if (missionId == null) return;
    final maps = Get.find<MapsTabController>();

    final mission =
        maps.activeMissions.where((m) => m.id == missionId).firstOrNull ??
        await _loadMission(missionId);
    if (mission != null && mission.awaitingClientPayment) {
      maps.promptPaymentFor(mission);
    }
  }

  Future<void> _joinLive(String? missionId) async {
    final mission = missionId == null ? null : await _loadMission(missionId);
    if (mission == null) {
      Toast.error('This live is no longer available.');
      return;
    }

    if (_hasEnded(mission)) {
      await _openTab(0);
      Toast.info('That live has already ended.');
      return;
    }

    if (Get.isDialogOpen ?? false) Get.back();
    Get.find<MapsTabController>().shownSessions.add(mission.id!);
    Get.toNamed(AppRoutes.stream, arguments: mission);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _openMessage(RemoteMessage message) {
    final payload = _payloadOf(message);
    if (payload != null) open(payload);
  }

  void _onForeground(RemoteMessage message) {
    final payload = _payloadOf(message);
    if (payload == null) return;

    // The map tab already shows its own dialog for these.
    final sameRole = payload.type.role == RoleService.instance.role.value;
    final shownInApp =
        payload.type == NotificationType.scoutLive ||
        (payload.type == NotificationType.missionAccepted &&
            payload.awaitsPayment);
    if (sameRole && shownInApp) return;

    Toast.notify(
      payload.title ?? 'Zuru',
      payload.body ?? '',
      onTap: () => open(payload),
    );
  }

  Future<bool> _confirmSwitch(UserRole role) async {
    final label = role == UserRole.scout ? 'Guide' : 'Viewer';
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Switch to $label mode?'),
        content: Text(
          'This notification is for your $label account. Switch to $label '
          'mode to open it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<MissionEntity?> _loadMission(String missionId) async {
    final result = await _getMissionById(missionId);
    return result.fold((_) => null, (mission) => mission);
  }

  bool _hasEnded(MissionEntity mission) {
    const finished = {
      MissionStatus.completed,
      MissionStatus.cancelled,
      MissionStatus.declined,
    };
    final status = mission.recordingSession?.status;
    return finished.contains(mission.status) ||
        status == SessionStatus.ended ||
        status == SessionStatus.failed;
  }

  NotificationPayload? _payloadOf(RemoteMessage message) =>
      NotificationPayload.fromData(
        message.data,
        title: message.notification?.title,
        body: message.notification?.body,
      );

  static bool _isHome(String? route) =>
      route == AppRoutes.home || route == AppRoutes.scoutHome;

  static const _signedOutRoutes = {AppRoutes.login, AppRoutes.signup};
}
