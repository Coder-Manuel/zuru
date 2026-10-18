import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/modules/notifications/data/repositories_impl/notifications_repository_impl.dart';
import 'package:zuru/modules/notifications/data/sources/remote_notifications_datasource.dart';
import 'package:zuru/modules/notifications/domain/repository/notifications_repository.dart';
import 'package:zuru/modules/notifications/domain/usecases/mark_notification_read.usecase.dart';
import 'package:zuru/modules/notifications/presentation/services/notification_router.dart';

class NotificationsBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RemoteNotificationsDatasource>(
      () =>
          RemoteNotificationsDatasourceImpl(client: Get.find<SupabaseClient>()),
      fenix: true,
    );
    Get.lazyPut<NotificationsRepository>(
      () => NotificationsRepositoryImpl(
        remoteDatasource: Get.find<RemoteNotificationsDatasource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<MarkNotificationReadUseCase>(
      () => MarkNotificationReadUseCase(
        repo: Get.find<NotificationsRepository>(),
      ),
      fenix: true,
    );

    // After the missions and user bindings: the router uses both.
    Get.put<NotificationRouter>(NotificationRouter(), permanent: true);
  }
}
