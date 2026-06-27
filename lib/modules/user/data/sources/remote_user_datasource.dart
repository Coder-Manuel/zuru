import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/core/models/enums.dart';

abstract class RemoteUserDatasource {
  Future<Map<String, dynamic>?> getUseInfo();
  Future<void> updateFcmToken(String token);
  Future<void> updateDefaultRole(String role);

  // ── Scout World Profile ─────────────────────────────────────────────────
  /// Updates the scout's `profiles` row and returns the updated record.
  Future<Map<String, dynamic>?> updateScoutProfile(Map<String, dynamic> data);

  /// Uploads [file] to the `avatars` bucket and returns its public URL.
  Future<String> uploadMedia(File file, {required String folder});

  /// Fetches all clip rows for [profileId].
  Future<List<Map<String, dynamic>>> getProfileClips(String profileId);

  /// Inserts a new clip row and returns the persisted record.
  Future<Map<String, dynamic>> addProfileClip(Map<String, dynamic> data);

  Future<void> deleteProfileClip(String id);
}

class RemoteUserDatasourceImpl extends RemoteUserDatasource {
  final SupabaseClient client;

  RemoteUserDatasourceImpl({required this.client});

  String get _uid => client.auth.currentUser?.id ?? '';

  @override
  Future<Map<String, dynamic>?> getUseInfo() {
    return client.rpc('me').single();
  }

  @override
  Future<void> updateFcmToken(String token) {
    return client.from('users').update({'fcm_token': token}).eq('id', _uid);
  }

  @override
  Future<void> updateDefaultRole(String role) {
    return client.from('users').update({'default_role': role}).eq('id', _uid);
  }

  @override
  Future<Map<String, dynamic>?> updateScoutProfile(Map<String, dynamic> data) {
    return client
        .from('profiles')
        .update(data)
        .eq('user_id', _uid)
        .eq('role', UserRole.scout.name)
        .select()
        .single();
  }

  @override
  Future<String> uploadMedia(File file, {required String folder}) async {
    final dot = file.path.lastIndexOf('.');
    final ext = dot == -1 ? '' : file.path.substring(dot);
    final path = '$_uid/$folder/${DateTime.now().millisecondsSinceEpoch}$ext';

    await client.storage
        .from('avatars')
        .upload(path, file, fileOptions: const FileOptions(upsert: true));

    return client.storage.from('avatars').getPublicUrl(path);
  }

  @override
  Future<List<Map<String, dynamic>>> getProfileClips(String profileId) async {
    final result = await client
        .from('profile_clips')
        .select()
        .eq('profile_id', profileId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<Map<String, dynamic>> addProfileClip(Map<String, dynamic> data) {
    return client.from('profile_clips').insert(data).select().single();
  }

  @override
  Future<void> deleteProfileClip(String id) {
    return client.from('profile_clips').delete().eq('id', id);
  }
}
