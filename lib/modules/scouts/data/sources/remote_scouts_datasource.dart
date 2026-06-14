import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/core/models/enums.dart';

abstract class RemoteScoutsDatasource {
  /// Paginated scout feed. [from]/[to] are inclusive row indexes.
  /// Optionally filters to available scouts or by a single [tag].
  Future<List<Map<String, dynamic>>> getScoutsFeed({
    required int from,
    required int to,
    bool availableOnly = false,
    String? tag,
  });

  /// Full scout profile (by profile id) including embedded clips.
  Future<Map<String, dynamic>?> getScoutDetail(String profileId);
}

class RemoteScoutsDatasourceImpl extends RemoteScoutsDatasource {
  final SupabaseClient client;

  RemoteScoutsDatasourceImpl({required this.client});

  // Embed the parent user alongside the scout profile row so the repository
  // can reconstruct a full [User]/[Profile].
  static const _feedSelect = '*, users(*)';
  static const _detailSelect = '*, users(is_online), profile_clips(*)';

  @override
  Future<List<Map<String, dynamic>>> getScoutsFeed({
    required int from,
    required int to,
    bool availableOnly = false,
    String? tag,
  }) async {
    var query = client
        .from('profiles')
        .select(_feedSelect)
        .eq('role', UserRole.scout.name)
        .eq('status', UserStatus.active.name);
    // .neq('user_id', client.auth.currentUser?.id ?? '');

    if (availableOnly) {
      query = query.eq('availability', ScoutAvailability.available.name);
    }
    if (tag != null && tag.isNotEmpty) {
      // `tags` is stored as a comma-joined string — substring match it.
      query = query.ilike('tags', '%$tag%');
    }

    final result = await query
        .order('rating', ascending: false)
        .range(from, to);

    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Future<Map<String, dynamic>?> getScoutDetail(String profileId) {
    return client
        .from('profiles')
        .select(_detailSelect)
        .eq('id', profileId)
        .maybeSingle();
  }
}
