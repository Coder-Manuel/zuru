import 'package:zuru/core/entities/base.entity.dart';

enum RecordingStatus { starting, active, ending, complete, failed }

class SessionRecordingEntity extends BaseEntity {
  final RecordingStatus? status;
  final String? storagePath;
  final int? durationSec;
  final String? startedAt;
  final String? signedUrl;

  SessionRecordingEntity({
    super.id,
    super.createdAt,
    this.status,
    this.storagePath,
    this.durationSec,
    this.startedAt,
    this.signedUrl,
  });

  bool get isProcessing =>
      status == RecordingStatus.starting ||
      status == RecordingStatus.active ||
      status == RecordingStatus.ending;

  bool get isPlayable =>
      status == RecordingStatus.complete && (signedUrl?.isNotEmpty ?? false);
}
