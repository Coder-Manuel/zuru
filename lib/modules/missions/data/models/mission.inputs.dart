import 'package:zuru/modules/missions/data/models/enum.dart';

// ── Scout inputs ──────────────────────────────────────────────────────────────

class NearbyMissionsInput {
  final double lat;
  final double lng;
  final double radiusMeters;

  const NearbyMissionsInput({
    required this.lat,
    required this.lng,
    this.radiusMeters = 2000,
  });

  Map<String, dynamic> toMap() => {
    'lat': lat,
    'lng': lng,
    'radius_m': radiusMeters,
  };
}

class AcceptMissionInput {
  final String missionId;
  const AcceptMissionInput({required this.missionId});
}

class WatchActiveMissionInput {
  final double scoutLat;
  final double scoutLng;
  final String? profileId;
  const WatchActiveMissionInput({
    this.profileId,
    this.scoutLat = 0,
    this.scoutLng = 0,
  });
}

class UpdateMissionStatusInput {
  final String missionId;
  final MissionStatus status;
  const UpdateMissionStatusInput({
    required this.missionId,
    required this.status,
  });
}

// ── Client inputs ─────────────────────────────────────────────────────────────

class PostMissionInput {
  /// Human-readable address shown in the UI banner.
  final String address;

  final double latitude;
  final double longitude;

  /// Free-text instructions for the scout.
  final String description;

  /// ISO 4217 currency code, e.g. "KES", "USD".
  final String currency;

  final double price;

  /// Requested duration in seconds.
  final int durationInSec;

  final MissionType missionType;

  PostMissionInput({
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.currency,
    required this.price,
    required this.durationInSec,
    required this.missionType,
  });

  Map<String, dynamic> toMap() => {
    'address': address,
    // PostGIS POINT — Supabase accepts WKT for geography columns.
    'location': 'POINT($longitude $latitude)',
    'description': description,
    'currency': currency,
    'price': price,
    'duration_in_sec': durationInSec,
    'type': missionType.apiValue,
  };
}
