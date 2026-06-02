import 'package:zuru/modules/stream/domain/entities/livekit_session.entity.dart';

/// Data-layer model for [LiveKitSessionEntity].
///
/// Owns the `fromMap` deserialisation of the `livekit-init` edge-function
/// response body.  The datasource returns a raw [Map]; this class converts it
/// into a strongly-typed domain object — that conversion happens in the
/// repository, not in the datasource.
class LiveKitSessionModel extends LiveKitSessionEntity {
  const LiveKitSessionModel({
    required super.token,
    required super.url,
    required super.roomName,
  });

  factory LiveKitSessionModel.fromMap(Map<String, dynamic> map) =>
      LiveKitSessionModel(
        token: map['token'] as String? ?? '',
        url: map['url'] ?? '',
        roomName: map['room_name'] ?? '',
      );
}
