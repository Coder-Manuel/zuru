import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/core/services/monitor_service/monitor.service.dart';
import 'package:zuru/core/services/role_service/role_service.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';

abstract class RemoteMissionsDatasource {
  // ── Client ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> postMission(Map<String, dynamic> data);
  Future<Map<String, dynamic>> createLiveRequest(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getNearbyScouts(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getMyMissions();
  Stream<List<Map<String, dynamic>>> watchActiveMissions();
  Stream<Map<String, dynamic>> watchLiveSessions(List<String> missions);

  // ── Scout ─────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getScoutMissions();
  Stream<List<Map<String, dynamic>>> watchNearbyMissions(
    Map<String, dynamic> data,
  );
  Future<bool> acceptMission(String missionId);
  Stream<Map<String, dynamic>?> watchScoutActiveMission(String? profileId);
  Future<Map<String, dynamic>?> updateMissionStatus({
    required String missionId,
    required String status,
  });
}

class RemoteMissionsDatasourceImpl extends RemoteMissionsDatasource {
  final SupabaseClient client;

  RemoteMissionsDatasourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> postMission(Map<String, dynamic> data) {
    return client.from('missions').insert(data).select().single();
  }

  @override
  Future<Map<String, dynamic>> createLiveRequest(Map<String, dynamic> data) {
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
  Future<List<Map<String, dynamic>>> getMyMissions() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];

    final role = RoleService.instance.role.value.name;

    var query = client
        .from('missions')
        .select("""
        *,
        client:client_id!inner (
          id,
          user_id,
          first_name,
          last_name,
          avatar_url,
          rating,
          total_reviews
        ),
        scout:scout_id!inner (
          id,
          user_id,
          first_name,
          last_name,
          avatar_url,
          rating,
          total_reviews
        ),
        ratings!ratings_mission_id_fkey (
          id,
          from_profile_id,
          to_profile_id,
          score
        )
      """)
        .eq('$role.user_id', userId);

    return query.order('created_at', ascending: false);
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
            client:client_id!inner (
              id,
              user_id
            ),
            scout:scout_id!inner (
              id,
              user_id,
              first_name,
              last_name,
              rating,
              total_reviews
            )
            """)
            .eq('client.user_id', userId ?? '')
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
    final ctrl = StreamController<Map<String, dynamic>>.broadcast();
    RealtimeChannel? channel;

    final userId = client.auth.currentUser?.id;

    void streamData(PostgresChangePayload payload) {
      if (ctrl.isClosed) return;
      final res = payload.newRecord;
      if (!ctrl.isClosed) ctrl.add(Map<String, dynamic>.from(res));
    }

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

    ctrl.onCancel = () {
      client.removeChannel(channel!);
      ctrl.close();
    };

    return ctrl.stream;
  }

  // ── Scout ─────────────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getScoutMissions() {
    return client
        .from('missions')
        .select("""
          *,
          client:client_id (
            id,
            user_id,
            first_name,
            last_name,
            rating,
            total_reviews
          ),
          ratings!ratings_mission_id_fkey (
            id,
            from_profile_id,
            to_profile_id,
            score
          )
          """)
        .eq('scout_id', client.auth.currentUser?.id ?? '')
        .order('created_at', ascending: false);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchNearbyMissions(
    Map<String, dynamic> data,
  ) {
    final ctrl = StreamController<List<Map<String, dynamic>>>.broadcast();
    Timer? debounceTimer;
    RealtimeChannel? channel;

    Future<void> fetchNearby() async {
      if (ctrl.isClosed) return;
      try {
        List raw = await client.rpc('get_missions_within_radius', params: data);
        final rows = raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (!ctrl.isClosed) ctrl.add(rows);
      } catch (e, stack) {
        MonitorService.report(
          ex: e,
          library: 'missions_datasource',
          description: 'while calling get_missions_within_radius RPC',
          stack: stack,
        );
        if (!ctrl.isClosed) ctrl.addError(e);
      }
    }

    void debouncedFetch() {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 300), fetchNearby);
    }

    channel = client
        .channel('nearby_missions_watch')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'missions',
          callback: (_) => debouncedFetch(),
        )
        .subscribe();

    fetchNearby();

    ctrl.onCancel = () {
      debounceTimer?.cancel();
      client.removeChannel(channel!);
      ctrl.close();
    };

    return ctrl.stream;
  }

  @override
  Future<bool> acceptMission(String missionId) {
    return client.rpc<bool>(
      'accept_mission',
      params: {'p_mission_id': missionId},
    );
  }

  @override
  Stream<Map<String, dynamic>?> watchScoutActiveMission(String? profileId) {
    final ctrl = StreamController<Map<String, dynamic>?>.broadcast();
    Timer? debounceTimer;
    RealtimeChannel? channel;

    final userId = client.auth.currentUser?.id;

    Future<void> fetchActive() async {
      if (ctrl.isClosed) return;
      if (userId == null || profileId == null) {
        if (!ctrl.isClosed) ctrl.add(null);
        return;
      }
      try {
        final res = await client
            .from('missions')
            .select("""
              *,
              scout:scout_id (
                id,
                user_id
              ),
              client:client_id (
                id,
                user_id,
                first_name,
                last_name,
                rating,
                total_reviews
              )
            """)
            .eq('scout_id.user_id', userId)
            .inFilter('status', [
              MissionStatus.accepted.name,
              MissionStatus.enroute.name,
              MissionStatus.live.name,
            ])
            .limit(1)
            .maybeSingle();

        if (!ctrl.isClosed) {
          ctrl.add(res != null ? Map<String, dynamic>.from(res) : null);
        }
      } catch (e, stack) {
        MonitorService.report(
          ex: e,
          library: 'missions_datasource',
          description: 'while fetching active mission',
          stack: stack,
        );
        if (!ctrl.isClosed) ctrl.addError(e);
      }
    }

    void debouncedFetch() {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 300), fetchActive);
    }

    if (profileId != null) {
      channel = client
          .channel('active_mission_watch_$profileId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'missions',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'scout_id',
              value: profileId,
            ),
            callback: (_) => debouncedFetch(),
          )
          .subscribe();
    }

    fetchActive();

    ctrl.onCancel = () {
      debounceTimer?.cancel();
      if (channel != null) client.removeChannel(channel);
      ctrl.close();
    };

    return ctrl.stream;
  }

  @override
  Future<Map<String, dynamic>?> updateMissionStatus({
    required String missionId,
    required String status,
  }) {
    return client
        .from('missions')
        .update({'status': status})
        .eq('id', missionId)
        .select("""
          *,
          client:client_id (
            id,
            user_id,
            first_name,
            last_name,
            rating,
            total_reviews
          )
        """)
        .single();
  }
}
