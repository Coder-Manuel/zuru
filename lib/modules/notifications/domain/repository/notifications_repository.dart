import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/notifications/domain/entities/app_notification.entity.dart';

abstract class NotificationsRepository {
  Stream<RepoResponse<List<AppNotification>>> watch(String profileId);
  Future<RepoResponse<void>> markRead(String notificationId);
  Future<RepoResponse<void>> markAllRead(String profileId);
}
