import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/entities/mission_page.entity.dart';

// ── Scout inputs ──────────────────────────────────────────────────────────────

/// One page of the scout's live-check pool (`search_missions`).
class SearchMissionsInput {
  final double lat;
  final double lng;
  final MissionSort sort;
  final int limit;

  /// The last row of the previous page; null for the first page.
  final MissionPageCursor? cursor;

  /// The app's USD → KES rate so "Highest pay" ranks USD and KES missions
  /// together. It only affects ordering.
  final double? usdToKes;

  const SearchMissionsInput({
    required this.lat,
    required this.lng,
    this.sort = MissionSort.nearest,
    this.limit = 20,
    this.cursor,
    this.usdToKes,
  });

  Map<String, dynamic> toMap() => {
    'p_lat': lat,
    'p_lng': lng,
    'p_sort': sort.apiValue,
    'p_limit': limit,
    if (cursor != null) 'p_cursor_key': cursor!.sortKey,
    if (cursor != null) 'p_cursor_id': cursor!.id,
    if (usdToKes != null) 'p_usd_kes': usdToKes,
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

class DeclineMissionInput {
  final MissionEntity mission;

  const DeclineMissionInput({required this.mission});
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
