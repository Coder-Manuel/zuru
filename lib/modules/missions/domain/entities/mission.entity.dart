import 'package:zuru/core/entities/base.entity.dart';
import 'package:zuru/core/entities/profile.entity.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/data/models/live_request_payment.config.dart';
import 'package:zuru/modules/missions/domain/entities/session.entity.dart';
import 'package:zuru/modules/missions/domain/entities/session_recording.entity.dart';
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

  // ── Payment state ─────────────────────────────────────────────────────────

  /// How long the client has to pay after a guide accepts a live request.
  /// Kept in sync with `app_config` by [MissionsBindings].
  static Duration paymentWindow = LiveRequestPaymentConfig.fallbackWindow;

  bool get isLiveRequest => type == MissionType.liveRequest;

  /// A live request sitting with the guide, unanswered. The client owes
  /// nothing until the guide accepts.
  bool get awaitingScoutResponse =>
      isLiveRequest && !isPublished && status == MissionStatus.requested;

  /// The guide accepted but the client hasn't paid yet — the guide is blocked
  /// from starting until the payment lands.
  bool get awaitingClientPayment =>
      isLiveRequest && !isPublished && status == MissionStatus.accepted;

  /// True when the client can pay right now: an unpaid pool live check, or a
  /// live request a guide has already accepted.
  bool get isPayable =>
      !isPublished &&
      (awaitingClientPayment ||
          (!isLiveRequest && status == MissionStatus.open));

  /// UTC deadline for [awaitingClientPayment]; null when [acceptedAt] is
  /// unknown.
  DateTime? get paymentDeadline {
    final raw = acceptedAt;
    final accepted = raw != null ? DateTime.tryParse(raw)?.toUtc() : null;
    return accepted?.add(paymentWindow);
  }

  /// Time left to pay before the request is released, or null when the
  /// deadline is unknown.
  Duration? get paymentTimeLeft {
    final deadline = paymentDeadline;
    if (deadline == null) return null;
    final left = deadline.difference(DateTime.now().toUtc());
    return left.isNegative ? Duration.zero : left;
  }

  // ── Recording helpers ─────────────────────────────────────────────────────

  static const Duration recordingGracePeriod = Duration(hours: 2);

  List<SessionRecordingEntity> get _recordings =>
      recordingSession?.recordings ?? const [];

  List<SessionRecordingEntity> get recordingParts =>
      _recordings.where((r) => r.isPlayable).toList()..sort(
        (a, b) => (a.startedAt ?? a.createdAt ?? '').compareTo(
          b.startedAt ?? b.createdAt ?? '',
        ),
      );

  List<String> get recordingUrls => [
    for (final r in recordingParts) r.signedUrl!,
  ];

  bool get hasRecording => recordingParts.isNotEmpty;

  DateTime? get _completedAtUtc {
    final raw = completedAt ?? recordingSession?.endedAt;
    return raw != null ? DateTime.tryParse(raw)?.toUtc() : null;
  }

  bool get _withinRecordingWindow {
    final done = _completedAtUtc;
    if (done == null) return true;
    return DateTime.now().toUtc().difference(done) < recordingGracePeriod;
  }

  bool get _recordingExpected =>
      status == MissionStatus.completed &&
      recordingSession != null &&
      !hasRecording;

  bool get recordingProcessing =>
      _recordingExpected &&
      _withinRecordingWindow &&
      _recordings.any((r) => r.isProcessing);

  bool get recordingUnavailable => _recordingExpected && !recordingProcessing;

  int? get recordingDurationSec {
    final durations = recordingParts.map((r) => r.durationSec).whereType<int>();
    if (durations.isEmpty) return recordingSession?.actualDurationSec;
    return durations.reduce((a, b) => a + b);
  }

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
