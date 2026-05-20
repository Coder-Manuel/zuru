import 'package:supabase_flutter/supabase_flutter.dart';

abstract class RemoteStreamDatasource {
  /// Invokes the `go-live` edge function with [missionId].
  Future<FunctionResponse> joinStream({required String missionId});
}

class RemoteStreamDatasourceImpl implements RemoteStreamDatasource {
  final SupabaseClient client;

  RemoteStreamDatasourceImpl({required this.client});

  @override
  Future<FunctionResponse> joinStream({required String missionId}) {
    return client.functions.invoke('go-live', body: {'mission_id': missionId});
  }
}
