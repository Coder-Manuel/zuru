import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/notifications/domain/repository/notifications_repository.dart';

class MarkNotificationReadUseCase {
  final NotificationsRepository repo;

  MarkNotificationReadUseCase({required this.repo});

  Future<RepoResponse<void>> call(String notificationId) =>
      repo.markRead(notificationId);
}
