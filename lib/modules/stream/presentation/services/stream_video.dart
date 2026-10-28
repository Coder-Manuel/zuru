import 'package:livekit_client/livekit_client.dart';

/// Video settings for live streams. A guide streams the back camera to one
/// viewer (plus the recorder), so picture clarity comes first.
class StreamVideo {
  StreamVideo._();

  /// 720p at up to 2.5 Mbps. The SDK's 720p preset caps at 1.7 Mbps, which
  /// smears detailed outdoor scenes.
  static const _camera = VideoParameters(
    dimensions: VideoDimensionsPresets.h720_169,
    encoding: VideoEncoding(maxBitrate: 2500 * 1000, maxFramerate: 30),
  );

  /// The guide's room.
  static const publisherRoomOptions = RoomOptions(
    adaptiveStream: true,
    dynacast: true,
    defaultCameraCaptureOptions: CameraCaptureOptions(
      cameraPosition: CameraPosition.back,
      params: _camera,
    ),
    defaultVideoPublishOptions: VideoPublishOptions(
      // Hardware-encoded on iOS and nearly every Android phone. VP8, the SDK
      // default, is software-encoded there, and WebRTC sheds resolution to
      // relieve the CPU even on a fast network.
      videoCodec: 'h264',
      videoEncoding: VideoEncoding(maxBitrate: 2500 * 1000, maxFramerate: 30),
      // Fallback layers for weak links; never below 360p.
      videoSimulcastLayers: [
        VideoParametersPresets.h360_169,
        VideoParametersPresets.h540_169,
      ],
      // A site check needs detail: drop frames before dropping pixels. The
      // SDK default below 1080p is `balanced`, which scales the picture down
      // first.
      degradationPreference: DegradationPreference.maintainResolution,
    ),
  );

  /// The viewer's room. Adaptive stream asks the server for a layer sized to
  /// the view in logical pixels (no device pixel ratio), so a full-screen
  /// view on a 3x phone was served a layer about a third of the screen's
  /// resolution. With one full-screen track there is nothing to adapt:
  /// subscribe to the highest layer the connection allows.
  static const viewerRoomOptions = RoomOptions(
    adaptiveStream: false,
    dynacast: true,
  );
}
