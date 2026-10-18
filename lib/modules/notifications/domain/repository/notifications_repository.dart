import 'package:zuru/core/types/repo_reponse.type.dart';

abstract class NotificationsRepository {
  Future<RepoResponse<void>> markRead(String notificationId);
}
