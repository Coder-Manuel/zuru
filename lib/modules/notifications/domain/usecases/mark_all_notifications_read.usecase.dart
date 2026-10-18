import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/notifications/domain/repository/notifications_repository.dart';

class MarkAllNotificationsReadUseCase {
  final NotificationsRepository repo;

  MarkAllNotificationsReadUseCase({required this.repo});

  Future<RepoResponse<void>> call(String profileId) =>
      repo.markAllRead(profileId);
}
