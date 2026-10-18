import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/notifications/domain/entities/app_notification.entity.dart';
import 'package:zuru/modules/notifications/domain/repository/notifications_repository.dart';

class WatchNotificationsUseCase {
  final NotificationsRepository repo;

  WatchNotificationsUseCase({required this.repo});

  Stream<RepoResponse<List<AppNotification>>> call(String profileId) =>
      repo.watch(profileId);
}
