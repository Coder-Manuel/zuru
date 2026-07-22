import 'package:zuru/core/entities/base.entity.dart';
import 'package:zuru/core/entities/profile.entity.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/domain/entities/session.entity.dart';
import 'package:zuru/modules/rating/domain/entities/rating.entity.dart';

abstract class MissionEntity extends BaseEntity {
  final String? clientId;
  final String? scoutId;

  // ── Role-specific user snapshots ──────────────────────────────────────────
  /// Scout user snapshot (populated in client view).
  final Profile? scout;

  /// Client user snapshot (populated in scout view).
  final Profile? client;

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

  /// Scheduled start time for a [MissionType.liveRequest]; null = "now".
  final String? scheduledAt;

  // ── Scout radar canvas coordinates ────────────────────────────────────────
  /// Fractional X position on the scout's radar canvas (0–1).
  final double mapX;

  /// Fractional Y position on the scout's radar canvas (0–1).
  final double mapY;

  final String? acceptedAt;
  final String? completedAt;

  /// When the mission became visible to guides — set server-side once payment
  /// succeeds. Null means the mission is created but unpaid (draft).
  final String? publishedAt;

  final List<RatingEntity> ratings;

  /// The session behind this mission — carries the recording of a completed
  /// live check (populated in the client view). Null when there was no session.
  final SessionEntity? recordingSession;

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
    this.scheduledAt,
    this.mapX = 0,
    this.mapY = 0,
    this.acceptedAt,
    this.completedAt,
    this.publishedAt,
    this.ratings = const [],
    this.recordingSession,
  });

  /// True once payment has published the mission (visible to guides).
  bool get isPublished => publishedAt != null;

  // ── Recording helpers ─────────────────────────────────────────────────────

  /// How long after a live check is marked completed a recording may still be
  /// processing. Past this, a missing recording is treated as unavailable
  /// rather than "still processing".
  static const Duration recordingGracePeriod = Duration(hours: 2);

  /// Playable recording URL for this mission's session, or null.
  String? get recordingUrl => recordingSession?.recordingUrl;

  /// True when a completed live check has a ready, playable recording.
  bool get hasRecording => (recordingUrl?.isNotEmpty ?? false);

  /// When the live check was marked completed (falls back to the session's end
  /// time), in UTC. Null when unknown.
  DateTime? get _completedAtUtc {
    final raw = completedAt ?? recordingSession?.endedAt;
    return raw != null ? DateTime.tryParse(raw)?.toUtc() : null;
  }

  /// True while still inside the [recordingGracePeriod] after completion. When
  /// the completion time is unknown we optimistically assume we're still in the
  /// window rather than declaring the recording lost.
  bool get _withinRecordingWindow {
    final done = _completedAtUtc;
    if (done == null) return true;
    return DateTime.now().toUtc().difference(done) < recordingGracePeriod;
  }

  /// A recording is *expected* (a session ended for a completed check) but isn't
  /// available yet.
  bool get _recordingPending =>
      status == MissionStatus.completed &&
      recordingSession != null &&
      recordingSession?.status == SessionStatus.ended &&
      !hasRecording;

  /// Egress is still running and we're within the 2h grace window — drives the
  /// "processing" state on the card.
  bool get recordingProcessing => _recordingPending && _withinRecordingWindow;

  /// No recording will arrive: the session failed, or the 2h grace window has
  /// elapsed with no recording produced.
  bool get recordingUnavailable =>
      status == MissionStatus.completed &&
      !hasRecording &&
      (recordingSession?.status == SessionStatus.failed ||
          (_recordingPending && !_withinRecordingWindow));

  /// Recording length in seconds, when known.
  int? get recordingDurationSec => recordingSession?.actualDurationSec;

  // ── Rating helpers ────────────────────────────────────────────────────────
  bool get hasRatedByClient => ratings.any((r) => r.fromUserId == clientId);
  bool get hasRatedByScout => ratings.any((r) => r.fromUserId == scoutId);

  /// Backward-compat: in client context, "has rated" means the client rated.
  bool get hasRated => hasRatedByClient;

  bool get isMyMission;

  // ── Display helpers ───────────────────────────────────────────────────────

  /// A short, human-readable summary of [address] — at most 3 words.
  String get shortAddress {
    final raw = address.trim();
    if (raw.isEmpty) return 'Unknown area';

    var tokens = raw.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return 'Unknown area';

    // Drop a leading code token — a plot number ("12") or a Plus Code
    // ("123G+4R"): any first token containing a digit or a '+'.
    final first = tokens.first;
    final isCode = first.contains('+') || RegExp(r'\d').hasMatch(first);
    if (isCode && tokens.length > 1) tokens = tokens.sublist(1);

    // Cap to 3 words and strip any dangling trailing comma.
    return tokens.take(3).join(' ').replaceAll(RegExp(r',\s*$'), '');
  }

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
