import 'package:zuru/core/entities/base.entity.dart';
import 'package:zuru/modules/notifications/data/models/notification_type.dart';

/// A row of `public.notifications`, as shown in the in-app list.
abstract class AppNotification extends BaseEntity {
  /// Null for a type this build does not know.
  final NotificationType? type;
  final String? missionId;
  final String title;
  final String body;
  final String? readAt;

  AppNotification({
    super.id,
    super.createdAt,
    required this.type,
    required this.title,
    required this.body,
    this.missionId,
    this.readAt,
  });

  bool get isRead => readAt != null;
}
