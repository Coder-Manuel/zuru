import 'package:zuru/modules/notifications/data/models/notification_type.dart';

/// The `data` of a push, read into what the app acts on.
class NotificationPayload {
  final NotificationType type;
  final String? missionId;
  final String? notificationId;
  final String? title;
  final String? body;

  /// Every data field, for type-specific details such as `payment_window_min`.
  final Map<String, dynamic> data;

  const NotificationPayload({
    required this.type,
    this.missionId,
    this.notificationId,
    this.title,
    this.body,
    this.data = const {},
  });

  /// Null for a type this build does not know.
  static NotificationPayload? fromData(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    final type = NotificationType.fromApi(data['type']?.toString());
    if (type == null) return null;

    String? nonEmpty(Object? v) {
      final s = v?.toString();
      return s == null || s.isEmpty ? null : s;
    }

    return NotificationPayload(
      type: type,
      missionId: nonEmpty(data['mission_id']),
      notificationId: nonEmpty(data['notification_id']),
      title: title,
      body: body,
      data: data,
    );
  }

  /// An unpaid live request: the map tab already opens its payment prompt.
  bool get awaitsPayment => data['payment_window_min'] != null;
}
