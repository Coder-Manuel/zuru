import 'package:zuru/core/models/enums.dart';

/// What tapping a notification opens. The type alone decides it; the push
/// carries no route.
enum NotificationAction {
  /// Scout home → Radar tab.
  radar,

  /// Scout home → Tasks tab.
  tasks,

  /// Client home → Map tab.
  map,

  /// Client home → Map tab, then the payment prompt if it is still owed.
  payForMission,

  /// Client home → Live Checks tab.
  liveChecks,

  /// Straight into the live, unless it has ended.
  joinLive,
}

/// Mirrors the types the backend queues (`_shared/types.ts`).
enum NotificationType {
  liveRequestCreated('LIVE_REQUEST_CREATED', UserRole.scout),
  missionRequestPaid('MISSION_REQUEST_PAID', UserRole.scout),
  requestCancelled('REQUEST_CANCELLED', UserRole.scout),
  missionAccepted('MISSION_ACCEPTED', UserRole.client),
  missionEnroute('MISSION_ENROUTE', UserRole.client),
  scoutLive('SCOUT_LIVE', UserRole.client),
  missionDeclined('MISSION_DECLINED', UserRole.client),
  missionReleased('MISSION_RELEASED', UserRole.client),
  paymentExpired('PAYMENT_EXPIRED', UserRole.client);

  const NotificationType(this.apiValue, this.role);

  final String apiValue;

  /// The role the notification belongs to.
  final UserRole role;

  static NotificationType? fromApi(String? value) =>
      values.where((t) => t.apiValue == value).firstOrNull;

  NotificationAction get action => switch (this) {
    liveRequestCreated || missionRequestPaid => NotificationAction.radar,
    requestCancelled => NotificationAction.tasks,
    missionAccepted => NotificationAction.payForMission,
    missionEnroute => NotificationAction.map,
    scoutLive => NotificationAction.joinLive,
    missionDeclined ||
    missionReleased ||
    paymentExpired => NotificationAction.liveChecks,
  };
}
