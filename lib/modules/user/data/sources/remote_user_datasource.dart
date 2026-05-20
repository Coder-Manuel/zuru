import 'package:supabase_flutter/supabase_flutter.dart';

abstract class RemoteUserDatasource {
  Future<Map<String, dynamic>?> getUseInfo();
  Future<void> updateFcmToken(String token);
}

class RemoteUserDatasourceImpl extends RemoteUserDatasource {
  final SupabaseClient client;

  RemoteUserDatasourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>?> getUseInfo() {
    return client.rpc('me').single();
  }

  @override
  Future<void> updateFcmToken(String token) {
    final uid = client.auth.currentUser?.id ?? '';
    return client
        .from('users')
        .update({'fcm_token': token})
        .eq('id', uid);
  }
}
