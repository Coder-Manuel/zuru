import 'dart:async';

import 'package:get/get.dart';
import 'package:zuru/core/services/role_service/role_service.dart';
import 'package:zuru/modules/notifications/data/models/notification_payload.dart';
import 'package:zuru/modules/notifications/domain/entities/app_notification.entity.dart';
import 'package:zuru/modules/notifications/domain/usecases/mark_all_notifications_read.usecase.dart';
import 'package:zuru/modules/notifications/domain/usecases/mark_notification_read.usecase.dart';
import 'package:zuru/modules/notifications/domain/usecases/watch_notifications.usecase.dart';
import 'package:zuru/modules/notifications/presentation/services/notification_router.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

/// The in-app notification list for the active role: the scout Alerts tab and
/// the client notifications page both read it. Permanent, so the unread badge
/// stays current on every tab.
class NotificationsController extends GetxController {
  final _watch = Get.find<WatchNotificationsUseCase>();
  final _markRead = Get.find<MarkNotificationReadUseCase>();
  final _markAllRead = Get.find<MarkAllNotificationsReadUseCase>();
  final _userController = Get.find<UserController>();

  final RxList<AppNotification> notifications = <AppNotification>[].obs;

  /// Read here but not yet reflected by the realtime refetch.
  final RxSet<String> _readLocally = <String>{}.obs;

  StreamSubscription<dynamic>? _sub;
  String? _profileId;

  bool isRead(AppNotification n) => n.isRead || _readLocally.contains(n.id);
  int get unreadCount => notifications.where((n) => !isRead(n)).length;
  bool get hasUnread => unreadCount > 0;

  @override
  void onInit() {
    super.onInit();
    ever(_userController.currentUser, (_) => _subscribe());
    ever(RoleService.instance.role, (_) => _subscribe());
    _subscribe();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  String? get _activeProfileId {
    final user = _userController.currentUser.value;
    final role = RoleService.instance.role.value;
    return user?.profiles.where((p) => p.role == role).firstOrNull?.id;
  }

  void _subscribe() {
    final profileId = _activeProfileId;
    if (profileId == _profileId && _sub != null) return;

    _sub?.cancel();
    _sub = null;
    _profileId = profileId;
    notifications.clear();
    _readLocally.clear();
    if (profileId == null) return;

    _sub = _watch(profileId).listen(
      (response) => response.fold(
        (_) {}, // keep the last list on transient errors
        (items) {
          notifications.assignAll(items);
          _readLocally.removeWhere(
            (id) => items.any((n) => n.id == id && n.isRead),
          );
        },
      ),
      onError: (_) {},
    );
  }

  void onTap(AppNotification notification) {
    final id = notification.id;
    if (id != null) _readLocally.add(id);

    final type = notification.type;
    if (type == null) {
      if (id != null) _markRead(id);
      return;
    }

    // The router marks it read on the server.
    NotificationRouter.instance.open(
      NotificationPayload(
        type: type,
        missionId: notification.missionId,
        notificationId: id,
        title: notification.title,
        body: notification.body,
      ),
    );
  }

  Future<void> markAllRead() async {
    final profileId = _profileId;
    if (profileId == null || !hasUnread) return;
    _readLocally.addAll(notifications.map((n) => n.id).whereType<String>());
    await _markAllRead(profileId);
  }
}
