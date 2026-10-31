import 'package:zuru/modules/stream/domain/entities/stream_clock.entity.dart';

/// Data-layer model for [StreamClockEntity], from a `stream_clock` row.
class StreamClockModel extends StreamClockEntity {
  const StreamClockModel({
    required super.status,
    required super.endsAt,
    required super.serverNow,
    required super.receivedAt,
  });

  factory StreamClockModel.fromMap(
    Map<String, dynamic> map, {
    required DateTime receivedAt,
  }) {
    final endsAt = map['ends_at'] as String?;
    return StreamClockModel(
      status: map['status'] as String? ?? 'created',
      endsAt: endsAt == null ? null : DateTime.parse(endsAt),
      serverNow: DateTime.parse(map['server_now'] as String),
      receivedAt: receivedAt,
    );
  }
}
