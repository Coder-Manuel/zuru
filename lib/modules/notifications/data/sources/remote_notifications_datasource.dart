import 'package:supabase_flutter/supabase_flutter.dart';

abstract class RemoteNotificationsDatasource {
  Future<void> markRead(String notificationId);
}

class RemoteNotificationsDatasourceImpl extends RemoteNotificationsDatasource {
  final SupabaseClient client;

  RemoteNotificationsDatasourceImpl({required this.client});

  @override
  Future<void> markRead(String notificationId) {
    return client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', notificationId)
        .isFilter('read_at', null);
  }
}
