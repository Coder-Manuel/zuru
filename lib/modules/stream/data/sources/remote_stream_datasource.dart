import 'package:supabase_flutter/supabase_flutter.dart';

abstract class RemoteStreamDatasource {
  Future<FunctionResponse> goLive({required String missionId});

  /// The `stream_clock` row, or null when the session does not exist yet.
  Future<Map<String, dynamic>?> streamClock({required String missionId});

  Future<FunctionResponse> endSession({required String missionId});
}

class RemoteStreamDatasourceImpl implements RemoteStreamDatasource {
  final SupabaseClient client;

  RemoteStreamDatasourceImpl({required this.client});

  @override
  Future<FunctionResponse> goLive({required String missionId}) {
    return client.functions.invoke('go-live', body: {'mission_id': missionId});
  }

  @override
  Future<Map<String, dynamic>?> streamClock({required String missionId}) async {
    final List rows = await client.rpc(
      'stream_clock',
      params: {'p_mission_id': missionId},
    );
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  @override
  Future<FunctionResponse> endSession({required String missionId}) {
    return client.functions.invoke(
      'end-session',
      body: {'mission_id': missionId},
    );
  }
}
