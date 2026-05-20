import 'package:zuru/modules/missions/domain/entities/session.entity.dart';

class SessionModel extends SessionEntity {
  SessionModel({
    super.id,
    super.createdAt,
    super.updatedAt,
    super.missionId,
    super.provider,
    super.roomName,
    super.hostToken,
    super.clientToken,
    super.status,
    super.scheduledDurationSec,
    super.actualDurationSec,
    super.recordingId,
    super.recordingUrl,
    super.startedAt,
    super.endedAt,
  });

  factory SessionModel.fromMap(Map<String, dynamic> data) => SessionModel(
    id: data['id']?.toString(),
    createdAt: data['created_at']?.toString(),
    updatedAt: data['updated_at']?.toString(),
    missionId: data['mission_id']?.toString(),
    provider: data['provider']?.toString(),
    roomName: data['room_name']?.toString(),
    hostToken: data['host_token']?.toString(),
    clientToken: data['client_token']?.toString(),
    status: _parseStatus(data['status']?.toString()),
    scheduledDurationSec: data['scheduled_duration_sec'] as int?,
    actualDurationSec: data['actual_duration_sec'] as int?,
    recordingId: data['recording_id']?.toString(),
    recordingUrl: data['recording_url']?.toString(),
    startedAt: data['started_at']?.toString(),
    endedAt: data['ended_at']?.toString(),
  );

  static SessionStatus? _parseStatus(String? value) => switch (value) {
    'scheduled' => SessionStatus.scheduled,
    'active' => SessionStatus.active,
    'ended' => SessionStatus.ended,
    'failed' => SessionStatus.failed,
    _ => null,
  };
}
