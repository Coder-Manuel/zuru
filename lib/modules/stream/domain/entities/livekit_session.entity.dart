/// Domain representation of an active LiveKit streaming session.
///
/// Returned by [StreamRepository.initStream] after the edge function
/// successfully creates/joins the mission room.
abstract class LiveKitSessionEntity {
  final String token;
  final String url;
  final String roomName;

  const LiveKitSessionEntity({
    required this.token,
    required this.url,
    required this.roomName,
  });
}
