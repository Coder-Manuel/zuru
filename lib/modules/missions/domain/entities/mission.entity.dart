import 'package:zuru/core/entities/base.entity.dart';
import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/rating/domain/entities/rating.entity.dart';

abstract class MissionEntity extends BaseEntity {
  final String? clientId;
  final String? scoutId;

  // ── Role-specific user snapshots ──────────────────────────────────────────
  /// Scout user snapshot (populated in client view).
  final User? scout;

  /// Client user snapshot (populated in scout view).
  final User? client;

  /// LiveKit session ID (client-side).
  final String? sessionId;

  final String description;
  final String currency;
  final double price;
  final int durationInSec;
  final String address;

  /// Decimal latitude derived from the PostGIS geography field.
  /// Nullable when parsed from a client-side response; defaults to 0 in
  /// scout-side responses (EWKB always present).
  final double? latitude;
  final double? longitude;

  final MissionStatus status;
  final MissionType? type;

  // ── Scout radar canvas coordinates ────────────────────────────────────────
  /// Fractional X position on the scout's radar canvas (0–1).
  final double mapX;

  /// Fractional Y position on the scout's radar canvas (0–1).
  final double mapY;

  final String? acceptedAt;
  final String? completedAt;
  final List<RatingEntity> ratings;

  MissionEntity({
    super.id,
    super.createdAt,
    super.updatedAt,
    this.scout,
    this.client,
    this.clientId,
    this.scoutId,
    this.sessionId,
    required this.description,
    required this.currency,
    required this.price,
    required this.durationInSec,
    required this.address,
    this.latitude,
    this.longitude,
    this.status = MissionStatus.open,
    this.type,
    this.mapX = 0,
    this.mapY = 0,
    this.acceptedAt,
    this.completedAt,
    this.ratings = const [],
  });

  // ── Rating helpers ────────────────────────────────────────────────────────
  bool get hasRatedByClient => ratings.any((r) => r.fromUserId == clientId);
  bool get hasRatedByScout => ratings.any((r) => r.fromUserId == scoutId);

  /// Backward-compat: in client context, "has rated" means the client rated.
  bool get hasRated => hasRatedByClient;

  // ── Display helpers ───────────────────────────────────────────────────────
  String get durationLabel {
    final minutes = durationInSec ~/ 60;
    if (minutes < 60) return '$minutes min';
    final hrs = minutes ~/ 60;
    final rem = minutes % 60;
    return rem > 0 ? '$hrs hr $rem min' : '$hrs hr';
  }

  String get formattedPrice => '$currency ${_fmt(price)}';
  String _fmt(double n) {
    final list = n.toString().split('.');
    final s = list.first;
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
