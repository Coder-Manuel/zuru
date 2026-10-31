import 'dart:async';

import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/rating/presentation/pages/rate_scout_page.dart';
import 'package:zuru/modules/stream/domain/entities/livekit_session.entity.dart';
import 'package:zuru/modules/stream/domain/usecases/get_stream_clock.usecase.dart';
import 'package:zuru/modules/stream/domain/usecases/join_stream.usecase.dart';
import 'package:zuru/modules/stream/presentation/services/reconnect_grace.dart';
import 'package:zuru/modules/stream/presentation/services/stream_audio.dart';
import 'package:zuru/modules/stream/presentation/services/stream_countdown.dart';
import 'package:zuru/modules/stream/presentation/services/stream_video.dart';

// ── Scout presence status ─────────────────────────────────────────────────────

enum ScoutStatus {
  /// Room joined but no video track has arrived yet.
  waiting,

  /// Scout is actively publishing video.
  streaming,

  /// Scout's microphone is muted (video may still be active).
  muted,

  /// Scout dropped; they have [ReconnectGrace.period] to come back.
  disconnected,

  /// Scout did not come back in time. They can still rejoin.
  left,
}

// ── Controller ────────────────────────────────────────────────────────────────

class JoinStreamController extends GetxController with StreamCountdown {
  final JoinStreamUseCase _joinStreamUseCase;

  @override
  final GetStreamClockUseCase clockUseCase;

  /// [room] is for tests; a page gets a fresh room by default.
  JoinStreamController({
    required JoinStreamUseCase joinStreamUseCase,
    required this.clockUseCase,
    Room? room,
  }) : _joinStreamUseCase = joinStreamUseCase,
       _room = room ?? Room(roomOptions: StreamVideo.viewerRoomOptions);

  @override
  late MissionEntity mission;

  final Room _room;

  EventsListener<RoomEvent>? _roomListener;
  StreamSubscription<List<MediaDevice>>? _audioDevicesSub;
  Timer? _participantEventTimer;
  bool _hasNavigatedAway = false;

  // ── Observables ───────────────────────────────────────────────────────────

  final isConnecting = true.obs;
  final hasError = false.obs;

  final scoutStatus = ScoutStatus.waiting.obs;
  final remoteVideoTrack = Rx<VideoTrack?>(null);

  /// Whether the client's microphone is currently active.
  final isMicEnabled = false.obs;

  /// True while the local client's own connection is recovering.
  final isReconnecting = false.obs;

  /// True once this device's connection is gone for good; the page offers
  /// [rejoin].
  final connectionLost = false.obs;
  final isRejoining = false.obs;

  /// Transient one-liner shown when a participant connects or disconnects.
  /// Auto-clears after [_eventDisplayDuration].
  final participantEvent = Rx<String?>(null);

  /// Counts down while the scout is gone.
  final scoutGrace = ReconnectGrace();

  /// Counts down while this device reconnects.
  final selfGrace = ReconnectGrace();

  static const _eventDisplayDuration = Duration(seconds: 4);

  String get _scoutName => mission.scout?.displayName ?? 'Guide';

  // ── Initialise ────────────────────────────────────────────────────────────

  Future<void> initialize(MissionEntity m) async {
    mission = m;

    final result = await _joinStreamUseCase(m.id!);

    await result.fold(
      (err) async {
        isConnecting.value = false;
        hasError.value = true;
      },
      (data) async {
        try {
          _attachRoomListeners();
          await _connect(data);
          _room.addListener(_refreshVideoTrack);
          _audioDevicesSub = StreamAudio.watchDevices();

          isConnecting.value = false;
          _syncPresence();
          // The server's deadline, so a rejoin shows the time actually left.
          unawaited(startClock());
        } catch (_) {
          isConnecting.value = false;
          hasError.value = true;
        }
      },
    );
  }

  Future<void> _connect(LiveKitSessionEntity data) async {
    // Before connecting: Android only sees Bluetooth headsets once the
    // permission is granted.
    await StreamAudio.ensureBluetoothAccess();
    await _room.connect(data.url, data.token);
    isMicEnabled.value = false;

    await Future.delayed(const Duration(milliseconds: 400));
    _refreshVideoTrack();

    // Route audio now that the WebRTC audio unit has fully settled.
    // Calling this too early (before the delay) tears down the audio
    // unit on iOS and silences incoming scout audio.  Loudspeaker unless
    // a headset is connected.
    await StreamAudio.routeOutput();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Toggle the local microphone on or off.
  Future<void> toggleMic() async {
    final next = !isMicEnabled.value;
    await _room.localParticipant?.setMicrophoneEnabled(next);
    isMicEnabled.value = next;

    // Enabling the mic initialises the WebRTC audio unit on iOS, which
    // resets the output route back to earpiece.  Re-apply the routing so the
    // client continues hearing the scout after unmuting.
    if (next) await StreamAudio.routeOutput();
  }

  /// Client voluntarily leaves — pops the page without opening the rating screen.
  Future<void> leaveStream() async {
    _hasNavigatedAway = true;
    await _teardown();
    Get.back();
  }

  /// Joins again with a fresh token after the connection was lost. The clock
  /// carries on from the server's deadline.
  Future<void> rejoin() async {
    if (isRejoining.value || _hasNavigatedAway) return;
    isRejoining.value = true;

    final result = await _joinStreamUseCase(mission.id!);
    final joined = await result.fold((_) async => false, (data) async {
      try {
        await _connect(data);
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
      _postEvent("You're back in the stream");
      return;
    }

    // go-live refuses a live check that is over.
    final clock = await syncClock();
    if (clock?.isOver == true) {
      await _onSessionEnded();
    } else {
      _postEvent("Couldn't rejoin. Check your connection.");
    }
  }

  // ── LiveKit event listeners ───────────────────────────────────────────────

  void _attachRoomListeners() {
    _roomListener = _room.createListener()
      // ── Room-level ────────────────────────────────────────────────────────
      ..on<RoomDisconnectedEvent>((e) => _onRoomDisconnected(e.reason))
      // ── Local client connectivity ─────────────────────────────────────────
      ..on<RoomReconnectingEvent>((_) {
        isReconnecting.value = true;
        selfGrace.start(_giveUpReconnecting);
      })
      ..on<RoomReconnectedEvent>((_) {
        isReconnecting.value = false;
        selfGrace.cancel();
        _syncPresence();
        unawaited(syncClock());
        _postEvent("You're back online");
      })
      // ── Remote participant lifecycle ──────────────────────────────────────
      ..on<ParticipantConnectedEvent>((_) => _onScoutBack())
      ..on<ParticipantDisconnectedEvent>((_) {
        // Our own reconnect drops and re-adds everyone; presence is re-read
        // once it settles.
        if (isReconnecting.value) return;
        if (_room.remoteParticipants.isEmpty) _onScoutDropped();
      })
      // The server flags a scout whose connection died before it gives up on
      // them, so the overlay shows at once instead of on a frozen frame.
      ..on<ParticipantConnectionQualityUpdatedEvent>((e) {
        if (e.participant is! RemoteParticipant) return;
        if (e.connectionQuality == ConnectionQuality.lost) {
          _onScoutDropped();
        } else if (scoutStatus.value == ScoutStatus.disconnected) {
          _onScoutBack();
        }
      })
      // ── Track subscription ────────────────────────────────────────────────
      ..on<TrackSubscribedEvent>((e) {
        if (e.track is VideoTrack) {
          remoteVideoTrack.value = e.track as VideoTrack;
          if (!_scoutAway) scoutStatus.value = ScoutStatus.streaming;
        }
      })
      ..on<TrackUnsubscribedEvent>((e) {
        if (e.track is VideoTrack) {
          remoteVideoTrack.value = null;
          if (!_scoutAway) scoutStatus.value = ScoutStatus.waiting;
        }
      })
      // ── Mute / unmute ─────────────────────────────────────────────────────
      ..on<TrackMutedEvent>((e) {
        if (e.participant is RemoteParticipant &&
            e.publication.kind == TrackType.AUDIO) {
          scoutStatus.value = ScoutStatus.muted;
        }
      })
      ..on<TrackUnmutedEvent>((e) {
        if (e.participant is RemoteParticipant &&
            e.publication.kind == TrackType.AUDIO) {
          scoutStatus.value = remoteVideoTrack.value != null
              ? ScoutStatus.streaming
              : ScoutStatus.waiting;
        }
      });
  }

  bool get _scoutAway =>
      scoutStatus.value == ScoutStatus.disconnected ||
      scoutStatus.value == ScoutStatus.left;

  /// The scout dropped. The stream stays open; they get the grace period to
  /// come back, and can still rejoin after it.
  void _onScoutDropped() {
    if (_scoutAway) return;
    scoutStatus.value = ScoutStatus.disconnected;
    _postEvent('$_scoutName disconnected');
    scoutGrace.start(() => scoutStatus.value = ScoutStatus.left);
  }

  void _onScoutBack() {
    scoutGrace.cancel();
    if (_scoutAway) {
      _postEvent('$_scoutName reconnected');
      scoutStatus.value = ScoutStatus.waiting;
    } else {
      _postEvent('$_scoutName joined');
    }
    _refreshVideoTrack();
  }

  /// Presence from who is actually in the room, not from one-off events.
  void _syncPresence() {
    if (_room.remoteParticipants.isEmpty) {
      // A scout who never showed up is "waiting", not "disconnected".
      if (scoutStatus.value != ScoutStatus.waiting) _onScoutDropped();
      return;
    }
    if (_scoutAway) _onScoutBack();
    _refreshVideoTrack();
  }

  Future<void> _onRoomDisconnected(DisconnectReason? reason) async {
    if (_hasNavigatedAway) return;
    switch (reason) {
      // The server closed the room: time ran out or the guide ended it.
      case DisconnectReason.roomDeleted:
      case DisconnectReason.participantRemoved:
        await _onSessionEnded();
      // Our own disconnect (leaving, or giving up on a reconnect).
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
    scoutGrace.cancel();
    connectionLost.value = true;
    remoteVideoTrack.value = null;

    // Time may have run out while we were offline.
    final clock = await syncClock();
    if (clock?.isOver == true) await _onSessionEnded();
  }

  Future<void> _onSessionEnded() async {
    if (_hasNavigatedAway) return;
    _hasNavigatedAway = true;
    await _teardown();
    Get.offNamed(RateScoutPage.route, arguments: mission);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Posts a transient event message and auto-clears it after the display duration.
  void _postEvent(String message) {
    participantEvent.value = message;
    _participantEventTimer?.cancel();
    _participantEventTimer = Timer(_eventDisplayDuration, () {
      participantEvent.value = null;
    });
  }

  void _refreshVideoTrack() {
    for (final participant in _room.remoteParticipants.values) {
      for (final pub in participant.videoTrackPublications) {
        if (pub.subscribed && pub.track != null) {
          remoteVideoTrack.value = pub.track as VideoTrack;
          if (scoutStatus.value != ScoutStatus.muted && !_scoutAway) {
            scoutStatus.value = ScoutStatus.streaming;
          }
          return;
        }
      }
    }
    if (scoutStatus.value == ScoutStatus.streaming) {
      scoutStatus.value = ScoutStatus.waiting;
    }
    remoteVideoTrack.value = null;
  }

  Future<void> _teardown() async {
    stopClock();
    scoutGrace.cancel();
    selfGrace.cancel();
    _participantEventTimer?.cancel();
    _participantEventTimer = null;
    await _audioDevicesSub?.cancel();
    _audioDevicesSub = null;
    _room.removeListener(_refreshVideoTrack);
    await _roomListener?.dispose();
    _roomListener = null;
    await _room.disconnect();
  }

  @override
  void onClose() {
    scoutGrace.cancel();
    selfGrace.cancel();
    _participantEventTimer?.cancel();
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
