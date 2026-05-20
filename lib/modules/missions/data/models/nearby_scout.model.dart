import 'package:zuru/core/models/user.model.dart';
import 'package:zuru/modules/missions/domain/entities/nearby_scout.entity.dart';

/// Data-layer model for [NearbyScout].
///
/// Delegates all user-field parsing to [UserModel.fromMap] — no duplication
/// of the mapping logic that already lives in the core user model.
class NearbyScoutModel extends NearbyScout {
  const NearbyScoutModel({required super.user, required super.distanceMeters});

  factory NearbyScoutModel.fromMap(Map<String, dynamic> data) =>
      NearbyScoutModel(
        // UserModel.fromMap handles every standard user field (id, names,
        // rating, totalReviews, isOnline, etc.). Extra RPC columns like
        // distance_meters are simply ignored by it.
        user: UserModel.fromMap(data),
        distanceMeters: (data['distance_meters'] as num?)?.toDouble() ?? 0,
      );
}
