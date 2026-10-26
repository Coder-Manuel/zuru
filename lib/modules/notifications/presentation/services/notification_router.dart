import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/routes/app_routes.dart';
import 'package:zuru/core/services/monitor_service/monitor.service.dart';
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

  static const _library = 'NotificationRouter';

  /// The optional arguments are for tests; the app uses Firebase and the
  /// signed-in user.
  NotificationRouter({
    Stream<RemoteMessage>? openedMessages,
    Stream<RemoteMessage>? foregroundMessages,
    Future<RemoteMessage?> Function()? initialMessage,
    bool Function()? isSignedIn,
    UserRole Function()? currentRole,
  }) : _openedMessages = openedMessages,
       _foregroundMessages = foregroundMessages,
       _initialMessage = initialMessage ?? NotificationService.initialMessage,
       _isSignedIn =
           isSignedIn ??
           (() => Get.find<UserController>().currentUser.value != null),
       _currentRole = currentRole ?? (() => RoleService.instance.role.value);

  final Stream<RemoteMessage>? _openedMessages;
  final Stream<RemoteMessage>? _foregroundMessages;
  final Future<RemoteMessage?> Function() _initialMessage;
  final bool Function() _isSignedIn;
  final UserRole Function() _currentRole;

  final _getMissionById = Get.find<GetMissionByIdUseCase>();
  final _markRead = Get.find<MarkNotificationReadUseCase>();

  NotificationPayload? _pending;
  bool _homeReached = false;

  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  @override
  void onInit() {
    super.onInit();
    _openedSub = (_openedMessages ?? NotificationService.openedMessages).listen(
      (message) => _openMessage(message, via: 'tap'),
    );
    _foregroundSub =
        (_foregroundMessages ?? NotificationService.foregroundMessages).listen(
          _onForeground,
        );
  }

  @override
  Future<void> onReady() async {
    super.onReady();
    final launch = await _initialMessage();
    if (launch != null) _openMessage(launch, via: 'launch');
  }

  @override
  void onClose() {
    _openedSub?.cancel();
    _foregroundSub?.cancel();
    super.onClose();
  }

  /// `GetMaterialApp.routingCallback`.
  void onRouteChanged(Routing? routing) {
    // Only a page route says where the user is. When a popup closes over
    // another popup, GetX reports a stale route name (e.g. /login right after
    // signing in), which used to look like signing out and parked every
    // later tap for good.
    if (routing == null || routing.route is! PageRoute) return;
    final route = routing.current;

    if (_isHome(route)) {
      _homeReached = true;
      final pending = _pending;
      _pending = null;
      if (pending != null) {
        // Let home build first: this runs inside a navigator callback, where
        // pushing a route or a dialog is not allowed. The callback only runs
        // once a frame is scheduled, so make sure one is.
        WidgetsBinding.instance
          ..addPostFrameCallback((_) => open(pending))
          ..ensureVisualUpdate();
      }
    } else if (_signedOutRoutes.contains(route)) {
      _homeReached = false;
      if (_pending != null) _trace('signed out, dropping ${_pending!.type}');
      _pending = null;
    }
  }

  Future<void> open(NotificationPayload payload) async {
    final what = '${payload.type.apiValue} (mission ${payload.missionId})';

    if (!_homeReached || !_isSignedIn()) {
      _pending = payload;
      _trace('$what: waiting until the user is home');
      return;
    }

    final id = payload.notificationId;
    if (id != null) unawaited(_markRead(id));

    if (Get.currentRoute == AppRoutes.stream) {
      _trace('$what: on a live, showing a toast instead');
      Toast.info(payload.body ?? 'Open it once your live ends.');
      return;
    }

    final role = payload.type.role;
    if (role != _currentRole()) {
      if (!await _confirmSwitch(role)) {
        _trace('$what: user kept their current role');
        return;
      }
      if (!await Get.find<UserController>().switchTo(role)) {
        _trace('$what: switching to ${role.name} failed');
        return;
      }
      await WidgetsBinding.instance.endOfFrame;
    }

    _trace('$what: ${payload.type.action.name}');
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
    } else {
      _trace('mission $missionId: nothing left to pay');
    }
  }

  Future<void> _joinLive(String? missionId) async {
    final mission = missionId == null ? null : await _loadMission(missionId);
    if (mission == null) {
      _trace('mission $missionId: not found, cannot join');
      Toast.error('This live is no longer available.');
      return;
    }

    if (_hasEnded(mission)) {
      _trace('mission $missionId: live already ended');
      await _openTab(0);
      Toast.info('That live has already ended.');
      return;
    }

    if (Get.isDialogOpen ?? false) Get.back();
    Get.find<MapsTabController>().shownSessions.add(mission.id!);
    Get.toNamed(AppRoutes.stream, arguments: mission);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _openMessage(RemoteMessage message, {required String via}) {
    final payload = _payloadOf(message);
    if (payload == null) {
      _trace('$via: ignored, unknown type "${message.data['type']}"');
      return;
    }
    _trace('$via: ${payload.type.apiValue}');
    open(payload);
  }

  void _onForeground(RemoteMessage message) {
    final payload = _payloadOf(message);
    if (payload == null) return;

    // FCM shows nothing while the app is open; at least make it heard.
    // Not during a live, where it would cut into the call audio.
    if (Get.currentRoute != AppRoutes.stream) {
      unawaited(NotificationService.playForegroundAlert(message));
    }

    // The map tab already shows its own dialog for these.
    final sameRole = payload.type.role == _currentRole();
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

  void _trace(String message) =>
      MonitorService.breadcrumb(message, library: _library);

  static bool _isHome(String? route) =>
      route == AppRoutes.home || route == AppRoutes.scoutHome;

  static const _signedOutRoutes = {AppRoutes.login, AppRoutes.signup};
}
