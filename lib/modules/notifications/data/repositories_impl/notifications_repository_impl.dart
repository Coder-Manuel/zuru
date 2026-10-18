import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/utils/error_wrapper.dart';
import 'package:zuru/modules/notifications/data/sources/remote_notifications_datasource.dart';
import 'package:zuru/modules/notifications/domain/repository/notifications_repository.dart';

class NotificationsRepositoryImpl extends NotificationsRepository {
  final _library = 'Notifications Repository';
  final RemoteNotificationsDatasource remoteDatasource;

  NotificationsRepositoryImpl({required this.remoteDatasource});

  @override
  Future<RepoResponse<void>> markRead(String notificationId) async {
    final response = await ErrorWrapper.async<RepoResponse<void>>(
      () async {
        await remoteDatasource.markRead(notificationId);
        return SuccessResponse(null);
      },
      onError: (_) => FailureResponse('Could not update the notification.'),
      library: _library,
      description: 'while marking a notification read',
    );
    return response!;
  }
}
