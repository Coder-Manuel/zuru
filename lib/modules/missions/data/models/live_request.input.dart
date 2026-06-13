import 'package:zuru/modules/missions/data/models/enum.dart';

/// Input payload for a client's "Request a Live" — a [MissionType.liveRequest]
/// mission pre-assigned to a specific scout, optionally scheduled.
///
/// Intentionally separate from `PostMissionInput`: it carries a target scout
/// and a schedule instead of a location.
class LiveRequestInput {
  /// Target scout's **profile** id (maps to `missions.scout_id`).
  final String scoutId;

  /// Free-text of what the client wants to see.
  final String description;

  /// ISO 4217 currency code, e.g. "KES".
  final String currency;

  /// Total the client pays (session fee + platform fee) — held in escrow.
  final double price;

  /// Requested duration in seconds.
  final int durationInSec;

  /// Scheduled start time. Null means "now".
  final DateTime? scheduledAt;

  const LiveRequestInput({
    required this.scoutId,
    required this.description,
    required this.currency,
    required this.price,
    required this.durationInSec,
    this.scheduledAt,
  });

  Map<String, dynamic> toMap() => {
    'scout_id': scoutId,
    'description': description,
    'currency': currency,
    'price': price,
    'duration_in_sec': durationInSec,
    'type': MissionType.liveRequest.apiValue,
    // location is intentionally omitted (null) for live requests.
    'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
  };
}
