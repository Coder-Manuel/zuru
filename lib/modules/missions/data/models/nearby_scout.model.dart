import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/models/profile.model.dart';
import 'package:zuru/core/models/user.model.dart';
import 'package:zuru/modules/missions/domain/entities/nearby_scout.entity.dart';

/// Data-layer model for [NearbyScout].
///
/// The `get_nearby_scouts` RPC returns one **flat** row per scout, mixing
/// profile columns (first_name, rating, tags, avatar_url…) with user columns
/// (phone, is_online, fcm_token). [UserModel.fromMap] cannot read that shape —
/// it expects profile fields nested under `profiles` — so this normalises the
/// row into the User + Profile shape the rest of the app already uses.
///
/// Without this, `user.scoutProfile` is null and every scout card renders
/// '--' for the name, '–' for the rating and '0 live checks'.
class NearbyScoutModel extends NearbyScout {
  const NearbyScoutModel({required super.user, required super.distanceMeters});

  factory NearbyScoutModel.fromMap(Map<String, dynamic> data) {
    // `id` is the PROFILE id — missions.scout_id references profiles.id.
    // `user_id` only appears if the RPC selects it; it stays null otherwise.
    final profile = ProfileModel.fromMap({
      'id': data['id'],
      'user_id': data['user_id'],
      'first_name': data['first_name'],
      'last_name': data['last_name'],
      'rating': data['rating'],
      'total_reviews': data['total_reviews'],
      'tags': data['tags'],
      'avatar_url': data['avatar_url'],
      'created_at': data['created_at'],
      'updated_at': data['updated_at'],
      // The RPC only ever returns active scouts, so these are implied by the
      // query rather than carried in the row.
      'role': UserRole.scout.name,
      'status': UserStatus.active.name,
    });

    return NearbyScoutModel(
      user: UserModel(
        id: data['user_id']?.toString(),
        phone: data['phone']?.toString(),
        fcmToken: data['fcm_token']?.toString(),
        isOnline: data['is_online'] as bool?,
        defaultRole: UserRole.scout,
        status: UserStatus.active,
        profiles: [profile],
      ),
      distanceMeters: (data['distance_meters'] as num?)?.toDouble() ?? 0,
    );
  }
}
