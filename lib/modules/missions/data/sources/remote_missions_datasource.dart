import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/core/services/monitor_service/monitor.service.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';

abstract class RemoteMissionsDatasource {
  Future<Map<String, dynamic>> postMission(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getNearbyScouts(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getMyMissions();
  Stream<List<Map<String, dynamic>>> watchActiveMissions();
  Stream<Map<String, dynamic>> watchLiveSessions(List<String> missions);
}

class RemoteMissionsDatasourceImpl extends RemoteMissionsDatasource {
  final SupabaseClient client;

  RemoteMissionsDatasourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> postMission(Map<String, dynamic> data) {
    return client.from('missions').insert(data).select().single();
  }

  @override
  Future<List<Map<String, dynamic>>> getNearbyScouts(
    Map<String, dynamic> data,
  ) async {
    final result = await client.rpc('get_nearby_scouts', params: data);
    return List<Map<String, dynamic>>.from(result as List);
  }

  @override
  Future<List<Map<String, dynamic>>> getMyMissions() {
    return client
        .from('missions')
        .select("""
          *,
          scout:scout_id (
            id,
            first_name,
            last_name,
            rating,
            total_reviews
          ),
          ratings!ratings_mission_id_fkey (
            id,
            from_user_id,
            to_user_id,
            score
          )
          """)
        .order('created_at', ascending: false);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchActiveMissions() {
    final statuses = MissionStatus.values
        .where((s) => s != MissionStatus.completed)
        .map((s) => s.name)
        .toList();

    // Use a broadcast controller so multiple listeners can attach without
    // triggering multiple subscriptions.
    final ctrl = StreamController<List<Map<String, dynamic>>>.broadcast();
    Timer? debounceTimer;
    RealtimeChannel? channel;

    final userId = client.auth.currentUser?.id;

    // ── PostGIS fetch ───────────────────────────────────────────────────────
    Future<void> fetchNearby() async {
      if (ctrl.isClosed) return;
      try {
        final res = await client
            .from('missions')
            .select("""
            *,
            scout:scout_id (
              id,
              first_name,
              last_name,
              rating,
              total_reviews
            )
            """)
            .eq('client_id', userId ?? '')
            .inFilter('status', statuses);

        final rows = res
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        if (!ctrl.isClosed) ctrl.add(rows);
      } catch (e, stack) {
        MonitorService.report(
          ex: e,
          library: 'missions_datasource',
          description: 'while watching active missions',
          stack: stack,
        );
        if (!ctrl.isClosed) ctrl.addError(e);
      }
    }

    // Debounced wrapper — prevents a burst of realtime events from hammering
    // the DB with back-to-back RPC calls.
    void debouncedFetch() {
      debounceTimer?.cancel();
      debounceTimer = Timer(Duration(milliseconds: 300), fetchNearby);
    }

    // ── Realtime subscription ───────────────────────────────────────────────
    // Listen to ALL changes on the missions table (not just status='active')
    // so that transitions away from 'active' (e.g. mission accepted/completed)
    // also trigger a refresh.
    channel = client
        .channel('active_missions_watch_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'missions',
          callback: (_) => debouncedFetch(),
        )
        .subscribe();

    // ── Initial fetch ───────────────────────────────────────────────────────
    fetchNearby();

    // ── Cleanup ─────────────────────────────────────────────────────────────
    ctrl.onCancel = () {
      debounceTimer?.cancel();
      client.removeChannel(channel!);
      ctrl.close();
    };

    return ctrl.stream;
  }

  @override
  Stream<Map<String, dynamic>> watchLiveSessions(List<String> missions) {
    // Use a broadcast controller so multiple listeners can attach without
    // triggering multiple subscriptions.
    final ctrl = StreamController<Map<String, dynamic>>.broadcast();
    RealtimeChannel? channel;

    final userId = client.auth.currentUser?.id;

    // ── PostGIS fetch ───────────────────────────────────────────────────────
    void streamData(PostgresChangePayload payload) {
      if (ctrl.isClosed) return;

      final res = payload.newRecord;

      if (!ctrl.isClosed) ctrl.add(Map<String, dynamic>.from(res));
    }

    // ── Realtime subscription ───────────────────────────────────────────────
    channel = client
        .channel('active_sessions_watch_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sessions',
          callback: streamData,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.inFilter,
            column: 'mission_id',
            value: missions,
          ),
        )
        .subscribe();

    // ── Cleanup ─────────────────────────────────────────────────────────────
    ctrl.onCancel = () {
      client.removeChannel(channel!);
      ctrl.close();
    };

    return ctrl.stream;
  }
}
