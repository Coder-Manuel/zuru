import 'package:zuru/modules/alerts/domain/entities/alert.entity.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';

class AlertModel extends AlertEntity {
  AlertModel({
    super.id,
    super.createdAt,
    required super.type,
    required super.title,
    required super.body,
    super.missionId,
    super.isRead,
  });

  /// Builds a "client requested a live session" alert from the mission that
  /// carried the request.
  ///
  /// The [id] is derived from the type + mission id so re-emissions of the same
  /// pending request (the realtime stream fires on every touch) collapse to a
  /// single alert instead of piling up duplicates.
  factory AlertModel.liveRequest(MissionEntity mission) {
    final client = mission.client?.displayName ?? 'A viewer';
    return AlertModel(
      id: '${AlertType.liveRequestCreated.storageValue}:${mission.id}',
      createdAt: mission.createdAt ?? DateTime.now().toUtc().toIso8601String(),
      type: AlertType.liveRequestCreated,
      title: 'New live request',
      body: '$client wants to start a live session at ${mission.address}.',
      missionId: mission.id,
      isRead: false,
    );
  }

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id']?.toString(),
      createdAt: json['created_at']?.toString(),
      type: AlertType.fromStorage(json['type']?.toString()),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      missionId: json['mission_id']?.toString(),
      isRead: json['is_read'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt,
    'type': type.storageValue,
    'title': title,
    'body': body,
    'mission_id': missionId,
    'is_read': isRead,
  };

  AlertModel copyWith({bool? isRead}) => AlertModel(
    id: id,
    createdAt: createdAt,
    type: type,
    title: title,
    body: body,
    missionId: missionId,
    isRead: isRead ?? this.isRead,
  );
}
