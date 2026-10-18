import 'package:zuru/modules/notifications/data/models/notification_type.dart';
import 'package:zuru/modules/notifications/domain/entities/app_notification.entity.dart';

class AppNotificationModel extends AppNotification {
  AppNotificationModel({
    super.id,
    super.createdAt,
    required super.type,
    required super.title,
    required super.body,
    super.missionId,
    super.readAt,
  });

  factory AppNotificationModel.fromMap(Map<String, dynamic> data) =>
      AppNotificationModel(
        id: data['id']?.toString(),
        createdAt: data['created_at']?.toString(),
        type: NotificationType.fromApi(data['type']?.toString()),
        title: data['title']?.toString() ?? '',
        body: data['body']?.toString() ?? '',
        missionId: data['mission_id']?.toString(),
        readAt: data['read_at']?.toString(),
      );

  AppNotificationModel markedRead() => AppNotificationModel(
    id: id,
    createdAt: createdAt,
    type: type,
    title: title,
    body: body,
    missionId: missionId,
    readAt: readAt ?? DateTime.now().toUtc().toIso8601String(),
  );
}
