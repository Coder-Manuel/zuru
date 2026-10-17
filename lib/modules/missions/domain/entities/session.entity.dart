import 'package:zuru/core/entities/base.entity.dart';
import 'package:zuru/modules/missions/domain/entities/session_recording.entity.dart';

enum SessionStatus { scheduled, active, ended, failed }

class SessionEntity extends BaseEntity {
  final String? missionId;

  /// Video provider, e.g. "livekit", "agora".
  final String? provider;
  final String? roomName;
  final String? hostToken;
  final String? clientToken;
  final SessionStatus? status;

  final int? scheduledDurationSec;
  final int? actualDurationSec;
  final List<SessionRecordingEntity> recordings;

  final String? startedAt;
  final String? endedAt;

  SessionEntity({
    super.id,
    super.createdAt,
    super.updatedAt,
    this.missionId,
    this.provider,
    this.roomName,
    this.hostToken,
    this.clientToken,
    this.status,
    this.scheduledDurationSec,
    this.actualDurationSec,
    this.recordings = const [],
    this.startedAt,
    this.endedAt,
  });
}
