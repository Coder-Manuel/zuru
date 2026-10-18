import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/utils/error_wrapper.dart';
import 'package:zuru/modules/notifications/data/models/app_notification.model.dart';
import 'package:zuru/modules/notifications/data/sources/remote_notifications_datasource.dart';
import 'package:zuru/modules/notifications/domain/entities/app_notification.entity.dart';
import 'package:zuru/modules/notifications/domain/repository/notifications_repository.dart';

class NotificationsRepositoryImpl extends NotificationsRepository {
  final _library = 'Notifications Repository';
  final RemoteNotificationsDatasource remoteDatasource;

  NotificationsRepositoryImpl({required this.remoteDatasource});

  @override
  Stream<RepoResponse<List<AppNotification>>> watch(String profileId) async* {
    yield* ErrorWrapper.stream<RepoResponse<List<AppNotification>>>(
      () async* {
        await for (final rows in remoteDatasource.watch(profileId)) {
          yield SuccessResponse(
            rows.map(AppNotificationModel.fromMap).toList(),
          );
        }
      },
      onError: (_) => FailureResponse('Could not load notifications.'),
      library: _library,
      description: 'while streaming notifications',
    );
  }

  @override
  Future<RepoResponse<void>> markRead(String notificationId) =>
      _update(() => remoteDatasource.markRead(notificationId));

  @override
  Future<RepoResponse<void>> markAllRead(String profileId) =>
      _update(() => remoteDatasource.markAllRead(profileId));

  Future<RepoResponse<void>> _update(Future<void> Function() run) async {
    final response = await ErrorWrapper.async<RepoResponse<void>>(
      () async {
        await run();
        return SuccessResponse(null);
      },
      onError: (_) => FailureResponse('Could not update the notification.'),
      library: _library,
      description: 'while marking notifications read',
    );
    return response!;
  }
}
