import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/core/services/monitor_service/monitor.service.dart';

abstract class RemoteNotificationsDatasource {
  /// The newest notifications for [profileId], re-emitted on every change.
  Stream<List<Map<String, dynamic>>> watch(String profileId);
  Future<void> markRead(String notificationId);
  Future<void> markAllRead(String profileId);
}

class RemoteNotificationsDatasourceImpl extends RemoteNotificationsDatasource {
  final SupabaseClient client;

  RemoteNotificationsDatasourceImpl({required this.client});

  static const _limit = 50;

  @override
  Stream<List<Map<String, dynamic>>> watch(String profileId) {
    final ctrl = StreamController<List<Map<String, dynamic>>>.broadcast();
    Timer? debounceTimer;
    RealtimeChannel? channel;

    Future<void> fetch() async {
      if (ctrl.isClosed) return;
      try {
        // Rows without a title haven't been through send-fcm yet.
        final res = await client
            .from('notifications')
            .select('id, type, mission_id, title, body, read_at, created_at')
            .eq('recipient_profile_id', profileId)
            .not('title', 'is', null)
            .order('created_at', ascending: false)
            .limit(_limit);

        if (!ctrl.isClosed) {
          ctrl.add(res.map((e) => Map<String, dynamic>.from(e)).toList());
        }
      } catch (e, stack) {
        MonitorService.report(
          ex: e,
          library: 'notifications_datasource',
          description: 'while fetching notifications',
          stack: stack,
        );
        if (!ctrl.isClosed) ctrl.addError(e);
      }
    }

    channel = client
        .channel('notifications_watch_$profileId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_profile_id',
            value: profileId,
          ),
          callback: (_) {
            debounceTimer?.cancel();
            debounceTimer = Timer(const Duration(milliseconds: 300), fetch);
          },
        )
        .subscribe();

    fetch();

    ctrl.onCancel = () {
      debounceTimer?.cancel();
      if (channel != null) client.removeChannel(channel);
      ctrl.close();
    };

    return ctrl.stream;
  }

  @override
  Future<void> markRead(String notificationId) {
    return client
        .from('notifications')
        .update({'read_at': _now})
        .eq('id', notificationId)
        .isFilter('read_at', null);
  }

  @override
  Future<void> markAllRead(String profileId) {
    return client
        .from('notifications')
        .update({'read_at': _now})
        .eq('recipient_profile_id', profileId)
        .isFilter('read_at', null);
  }

  String get _now => DateTime.now().toUtc().toIso8601String();
}
