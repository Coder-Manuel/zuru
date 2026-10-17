import 'package:zuru/modules/missions/domain/entities/session_recording.entity.dart';

class SessionRecordingModel extends SessionRecordingEntity {
  SessionRecordingModel({
    super.id,
    super.createdAt,
    super.status,
    super.storagePath,
    super.durationSec,
    super.startedAt,
    super.signedUrl,
  });

  factory SessionRecordingModel.fromMap(Map<String, dynamic> data) =>
      SessionRecordingModel(
        id: data['id']?.toString(),
        createdAt: data['created_at']?.toString(),
        status: RecordingStatus.values
            .where((s) => s.name == data['status'])
            .firstOrNull,
        storagePath: data['storage_path']?.toString(),
        durationSec: (data['duration_sec'] as num?)?.toInt(),
        startedAt: data['started_at']?.toString(),
        signedUrl: data['signed_url']?.toString(),
      );
}
