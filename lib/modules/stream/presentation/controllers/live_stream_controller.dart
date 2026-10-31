import 'dart:async';

import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/rating/presentation/pages/rate_client_page.dart';
import 'package:zuru/modules/stream/data/models/stream.inputs.dart';
import 'package:zuru/modules/stream/domain/entities/livekit_session.entity.dart';
import 'package:zuru/modules/stream/domain/usecases/end_session.usecase.dart';
import 'package:zuru/modules/stream/domain/usecases/get_stream_clock.usecase.dart';
import 'package:zuru/modules/stream/domain/usecases/go_live.usecase.dart';
import 'package:zuru/modules/stream/presentation/services/reconnect_grace.dart';
import 'package:zuru/modules/stream/presentation/services/stream_audio.dart';
import 'package:zuru/modules/stream/presentation/services/stream_countdown.dart';
import 'package:zuru/modules/stream/presentation/services/stream_video.dart';

/// Lifecycle of the remote client as observed from the LiveKit room.
enum ClientStreamState {
  /// Room connected, but no remote participant yet.
  waiting,

  /// Client present and watching the stream.
  joined,

  /// Client dropped; they have [ReconnectGrace.period] to come back.
  disconnected,

  /// Client did not come back in time. They can still rejoin.
  droppedOff,

  /// Room was terminated server-side — time to navigate away.
  terminated,
}

class LiveStreamController extends GetxController with StreamCountdown {
  final GoLiveUseCase _goLiveUseCase;
  final EndSessionUseCase _endSessionUseCase;

  @override
  final GetStreamClockUseCase clockUseCase;

  /// [room] is for tests; a page gets a fresh room by default.
  LiveStreamController({
    required GoLiveUseCase goLiveUseCase,
    required EndSessionUseCase endSessionUseCase,
    required this.clockUseCase,
    Room? room,
  }) : _goLiveUseCase = goLiveUseCase,
       _endSessionUseCase = endSessionUseCase,
       _room = room ?? Room(roomOptions: StreamVideo.publisherRoomOptions);

  @override
  late MissionEntity mission;

  final Room _room;
  EventsListener<RoomEvent>? _roomListener;
  StreamSubscription<List<MediaDevice>>? _audioDevicesSub;

  // ── Observable state ───────────────────────────────────────────────────────

  final isConnecting = true.obs;
  final isLive = false.obs;
  final hasError = false.obs;
  final isMicEnabled = true.obs;
  final isEndingMission = false.obs;
  final videoTrack = Rx<VideoTrack?>(null);

  /// Remote client lifecycle.
  final clientState = ClientStreamState.waiting.obs;

  /// Whether the remote client's microphone is currently muted.
  final clientMicMuted = false.obs;

  /// True while the guide's own connection is recovering.
  final isReconnecting = false.obs;

  /// True once the guide's connection is gone for good; the page offers
  /// [rejoin].
  final connectionLost = false.obs;
  final isRejoining = false.obs;

  /// Counts down while the client is gone.
  final clientGrace = ReconnectGrace();

  /// Counts down while this device reconnects.
  final selfGrace = ReconnectGrace();

  bool _hasNavigatedAway = false;

  // ── Initialise ────────────────────────────────────────────────────────────

  Future<void> initialize(MissionEntity mission) async {
    this.mission = mission;

    final result = await _goLiveUseCase(
      InitStreamInput(missionId: mission.id!),
    );

    await result.fold(
      (err) async {
        isConnecting.value = false;
        hasError.value = true;
      },
      (session) async {
        try {
          // Subscribe to room events BEFORE connecting so we don't miss early
          // participant-joined events.
          _attachRoomListener();
          await _connect(session);
          _audioDevicesSub = StreamAudio.watchDevices();
          _room.addListener(_refreshVideoTrack);

          isConnecting.value = false;
          isLive.value = true;

          // Rejoining a stream that already started: pick up the server's
          // deadline, and expect the client back if they are not here.
          await syncClock();
          if (hasServerClock && _room.remoteParticipants.isEmpty) {
            _onClientDropped();
          }
          _syncPresence();
        } catch (_) {
          isConnecting.value = false;
          hasError.value = true;
        }
      },
    );
  }

  Future<void> _connect(LiveKitSessionEntity session) async {
    // Before connecting: Android only sees Bluetooth headsets once the
    // permission is granted.
    await StreamAudio.ensureBluetoothAccess();
    await _room.connect(session.url, session.token);

    // Publish our camera and microphone tracks.  The mic track must be
    // published BEFORE we touch the audio session routing — changing the
    // speaker output while the WebRTC audio unit is still negotiating
    // tears down the audio unit on iOS and silences both directions.
    await _room.localParticipant?.setCameraEnabled(true);
    await _room.localParticipant?.setMicrophoneEnabled(true);
    isMicEnabled.value = true;

    // Allow WebRTC track negotiation to fully settle.
    await Future.delayed(const Duration(milliseconds: 500));

    // NOW it is safe to route audio.  iOS audio session is stable at
    // this point.  Loudspeaker unless a headset is connected.
    await StreamAudio.routeOutput();
    _refreshVideoTrack();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> toggleMic() async {
    final next = !isMicEnabled.value;
    await _room.localParticipant?.setMicrophoneEnabled(next);
    isMicEnabled.value = next;
  }

  /// Ends the live check for both sides: the server deletes the room, which
  /// closes the viewer's stream too. Offline, the server still ends it when
  /// time runs out.
  Future<void> endMission() async {
    if (isEndingMission.value) return;
    isEndingMission.value = true;
    await _endSessionUseCase(mission.id!);
    await _teardown();
    _navigateToRateMission();
  }

  /// Goes live again with a fresh token after the connection was lost. The
  /// clock carries on from the server's deadline.
  Future<void> rejoin() async {
    if (isRejoining.value || _hasNavigatedAway) return;
    isRejoining.value = true;

    final result = await _goLiveUseCase(
      InitStreamInput(missionId: mission.id!),
    );
    final joined = await result.fold((_) async => false, (session) async {
      try {
        await _connect(session);
        return true;
      } catch (_) {
        return false;
      }
    });
    isRejoining.value = false;

    if (joined) {
      connectionLost.value = false;
      _syncPresence();
      unawaited(syncClock());
      return;
    }

    // go-live refuses a live check that is over.
    final clock = await syncClock();
    if (clock?.isOver == true) await _onSessionEnded();
  }

  // ── LiveKit event listener ────────────────────────────────────────────────

  void _attachRoomListener() {
    final listener = _room.createListener();
    _roomListener = listener;

    listener
      ..on<ParticipantConnectedEvent>((_) => _onClientJoined())
      ..on<ParticipantDisconnectedEvent>((_) {
        // Our own reconnect drops and re-adds everyone; presence is re-read
        // once it settles. Without this, a guide coming back saw "Viewer
        // left" while the viewer was still watching.
        if (isReconnecting.value) return;
        if (_room.remoteParticipants.isEmpty) _onClientDropped();
      })
      // The server flags a client whose connection died before it gives up
      // on them.
      ..on<ParticipantConnectionQualityUpdatedEvent>((e) {
        if (e.participant is! RemoteParticipant) return;
        if (e.connectionQuality == ConnectionQuality.lost) {
          _onClientDropped();
        } else if (clientState.value == ClientStreamState.disconnected) {
          _onClientJoined();
        }
      })
      // Guard to audio tracks only — video mute events must not flip the mic UI.
      ..on<TrackMutedEvent>((e) {
        if (e.participant is RemoteParticipant &&
            e.publication.kind == TrackType.AUDIO) {
          clientMicMuted.value = true;
        }
      })
      ..on<TrackUnmutedEvent>((e) {
        if (e.participant is RemoteParticipant &&
            e.publication.kind == TrackType.AUDIO) {
          clientMicMuted.value = false;
        }
      })
      ..on<RoomReconnectingEvent>((_) {
        isReconnecting.value = true;
        selfGrace.start(_giveUpReconnecting);
      })
      ..on<RoomReconnectedEvent>((_) {
        isReconnecting.value = false;
        selfGrace.cancel();
        _syncPresence();
        unawaited(syncClock());
      })
      ..on<RoomDisconnectedEvent>((e) => _onRoomDisconnected(e.reason));
  }

  void _onClientJoined() {
    clientGrace.cancel();
    clientState.value = ClientStreamState.joined;
    // The client's first join starts the server's clock.
    if (!hasServerClock) unawaited(startClock());
  }

  /// The client dropped. They get the grace period to come back, and can
  /// still rejoin after it.
  void _onClientDropped() {
    if (clientState.value == ClientStreamState.disconnected ||
        clientState.value == ClientStreamState.droppedOff) {
      return;
    }
    clientState.value = ClientStreamState.disconnected;
    clientGrace.start(() => clientState.value = ClientStreamState.droppedOff);
  }

  /// Presence from who is actually in the room, not from one-off events.
  void _syncPresence() {
    if (_room.remoteParticipants.isNotEmpty) {
      _onClientJoined();
    } else if (clientState.value == ClientStreamState.joined) {
      _onClientDropped();
    }
  }

  Future<void> _onRoomDisconnected(DisconnectReason? reason) async {
    if (_hasNavigatedAway || isEndingMission.value) return;
    switch (reason) {
      // The server closed the room: time ran out.
      case DisconnectReason.roomDeleted:
      case DisconnectReason.participantRemoved:
        await _onSessionEnded();
      // Our own disconnect (giving up on a reconnect).
      case DisconnectReason.clientInitiated:
        break;
      default:
        await _onConnectionLost();
    }
  }

  void _giveUpReconnecting() {
    if (!isReconnecting.value) return;
    _room.disconnect();
    _onConnectionLost();
  }

  Future<void> _onConnectionLost() async {
    if (connectionLost.value || _hasNavigatedAway) return;
    isReconnecting.value = false;
    selfGrace.cancel();
    clientGrace.cancel();
    connectionLost.value = true;

    // Time may have run out while we were offline.
    final clock = await syncClock();
    if (clock?.isOver == true) await _onSessionEnded();
  }

  Future<void> _onSessionEnded() async {
    if (_hasNavigatedAway) return;
    clientState.value = ClientStreamState.terminated;
    await _teardown();
    _navigateToRateMission();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _refreshVideoTrack() {
    final publications = _room.localParticipant?.videoTrackPublications;
    if (publications == null || publications.isEmpty) return;
    final track = publications.first.track;
    if (track != null) videoTrack.value = track;
  }

  Future<void> _teardown() async {
    stopClock();
    clientGrace.cancel();
    selfGrace.cancel();
    await _audioDevicesSub?.cancel();
    _audioDevicesSub = null;
    _room.removeListener(_refreshVideoTrack);
    await _roomListener?.dispose();
    _roomListener = null;
    await _room.disconnect();
  }

  void _navigateToRateMission() {
    if (_hasNavigatedAway) return;
    _hasNavigatedAway = true;
    Get.offNamed(RateClientPage.route, arguments: mission);
  }

  @override
  void onClose() {
    clientGrace.cancel();
    selfGrace.cancel();
    _audioDevicesSub?.cancel();
    _room.removeListener(_refreshVideoTrack);
    _roomListener?.dispose();
    _releaseRoom();
    super.onClose();
  }

  /// Disconnects (if it ever connected) and disposes the room, which also
  /// stops the engine's timers. Each page owns its own room.
  Future<void> _releaseRoom() async {
    // Disconnecting a room that never connected waits for an event that
    // never comes and times out.
    if (_room.connectionState != ConnectionState.disconnected) {
      await _room.disconnect().catchError((_) {});
    }
    await _room.dispose().catchError((_) => true);
  }
}
