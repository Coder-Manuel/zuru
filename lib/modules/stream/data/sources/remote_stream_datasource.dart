import 'package:supabase_flutter/supabase_flutter.dart';

abstract class RemoteStreamDatasource {
  Future<FunctionResponse> joinStream({required String missionId});
  Future<FunctionResponse> goLive({required String missionId});
}

class RemoteStreamDatasourceImpl implements RemoteStreamDatasource {
  final SupabaseClient client;

  RemoteStreamDatasourceImpl({required this.client});

  @override
  Future<FunctionResponse> joinStream({required String missionId}) {
    return client.functions.invoke(
      'join-stream',
      body: {'mission_id': missionId},
    );
  }

  @override
  Future<FunctionResponse> goLive({required String missionId}) {
    return client.functions.invoke('go-live', body: {'mission_id': missionId});
  }
}
