import 'package:zuru/core/entities/user.entity.dart';

/// A [User] with [UserRole.scout] enriched with the straight-line distance
/// computed server-side by the `get_nearby_scouts` RPC.
///
/// This is a domain value object — it does NOT duplicate any [User] fields;
/// it simply composes one.
abstract class NearbyScout {
  final User user;

  /// Straight-line distance in metres from the mission location.
  final double distanceMeters;

  const NearbyScout({required this.user, required this.distanceMeters});
}
