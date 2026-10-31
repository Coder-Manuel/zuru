/// The server's clock for a live check, from the `stream_clock` RPC.
///
/// The deadline is server time: `started_at` (stamped once, on the client's
/// first join) plus the scheduled duration. Rejoining never restarts it.
abstract class StreamClockEntity {
  /// Session status: `created`, `live`, `ending` or `ended`.
  final String status;

  /// Null until the client first joins and the clock starts.
  final DateTime? endsAt;

  /// The server's time when it answered.
  final DateTime serverNow;

  /// This device's time when the answer arrived.
  final DateTime receivedAt;

  const StreamClockEntity({
    required this.status,
    required this.endsAt,
    required this.serverNow,
    required this.receivedAt,
  });

  bool get isOver => status == 'ending' || status == 'ended';

  /// [endsAt] on this device's clock, which can be off from the server's.
  DateTime? get deviceDeadline =>
      endsAt?.subtract(serverNow.difference(receivedAt));
}
