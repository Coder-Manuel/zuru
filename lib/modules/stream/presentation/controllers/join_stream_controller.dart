import 'dart:async';

import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/rating/presentation/pages/rate_scout_page.dart';
import 'package:zuru/modules/stream/domain/usecases/join_stream.usecase.dart';

// ── Scout presence status ─────────────────────────────────────────────────────

enum ScoutStatus {
  /// Room joined but no video track has arrived yet.
  waiting,

  /// Scout is actively publishing video.
  streaming,

  /// Scout's microphone is muted (video may still be active).
  muted,

  /// Scout left or dropped — waiting for a possible reconnect.
  disconnected,
}

// ── Controller ────────────────────────────────────────────────────────────────

class JoinStreamController extends GetxController {
  final JoinStreamUseCase _joinStreamUseCase;

  JoinStreamController({required JoinStreamUseCase joinStreamUseCase})
    : _joinStreamUseCase = joinStreamUseCase;

  late MissionEntity mission;

  final _room = Room(
    roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
  );

  EventsListener<RoomEvent>? _roomListener;
  Timer? _countdownTimer;
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

  /// Transient one-liner shown when a participant connects or disconnects.
  /// Auto-clears after [_eventDisplayDuration].
  final participantEvent = Rx<String?>(null);

  /// Remaining seconds, counts down from [mission.durationInSec] to zero.
  final remainingSeconds = Rx<int?>(null);

  /// True once the countdown hits zero.
  final isExceeded = false.obs;

  /// Seconds past the deadline (increments after [isExceeded] is true).
  final exceededSeconds = 0.obs;

  static const _reconnectThreshold = Duration(minutes: 3);
  static const _eventDisplayDuration = Duration(seconds: 4);

  // ── Computed ──────────────────────────────────────────────────────────────

  /// Main timer label: `MM:SS` countdown, then `+MM:SS` once exceeded.
  String get timerLabel {
    if (isExceeded.value) return '+${_format(exceededSeconds.value)}';
    final s = remainingSeconds.value;
    if (s == null) return _format(mission.durationInSec);
    return _format(s);
  }

  /// Non-null when ≤ 60 s remain — ready to drop straight into the UI.
  String? get endingSoonLabel {
    final s = remainingSeconds.value;
    if (s == null || s <= 0 || s > 60) return null;
    return 'Stream ends in ${s}s';
  }

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

          await _room.connect(data.url, data.token);

          _room.addListener(_refreshVideoTrack);
          await Future.delayed(const Duration(milliseconds: 400));
          _refreshVideoTrack();

          // Route audio to loudspeaker now that the WebRTC audio unit has
          // fully settled.  Calling this too early (before the delay) tears
          // down the audio unit on iOS and silences incoming scout audio.
          await _configureSpeaker();

          isConnecting.value = false;
          _startCountdown();
        } catch (_) {
          isConnecting.value = false;
          hasError.value = true;
        }
      },
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Toggle the local microphone on or off.
  Future<void> toggleMic() async {
    final next = !isMicEnabled.value;
    await _room.localParticipant?.setMicrophoneEnabled(next);
    isMicEnabled.value = next;

    // Enabling the mic initialises the WebRTC audio unit on iOS, which
    // resets the output route back to earpiece.  Re-apply loudspeaker
    // routing so the client continues hearing the scout after unmuting.
    if (next) await _configureSpeaker();
  }

  /// Routes incoming audio to the loudspeaker.
  ///
  /// Must be called AFTER the WebRTC audio unit is fully negotiated.
  /// [forceSpeakerOutput] uses `overrideOutputAudioPort(.speaker)` on iOS,
  /// which works correctly while a mic track is simultaneously active.
  Future<void> _configureSpeaker() async {
    try {
      await Hardware.instance.setSpeakerphoneOn(true, forceSpeakerOutput: true);
    } catch (_) {}
  }

  /// Client voluntarily leaves — pops the page without opening the rating screen.
  Future<void> leaveStream() async {
    _hasNavigatedAway = true;
    await _teardown();
    Get.back();
  }

  // ── LiveKit event listeners ───────────────────────────────────────────────

  void _attachRoomListeners() {
    final name = mission.scout?.scoutProfile?.displayName;
    _roomListener = _room.createListener()
      // ── Room-level ────────────────────────────────────────────────────────
      ..on<RoomDisconnectedEvent>((e) => _onRoomTerminated(e.reason))
      // ── Local client connectivity ─────────────────────────────────────────
      ..on<RoomReconnectingEvent>((_) {
        isReconnecting.value = true;
      })
      ..on<RoomReconnectedEvent>((_) {
        isReconnecting.value = false;
        _postEvent("You're back online");
      })
      // ── Remote participant lifecycle ──────────────────────────────────────
      ..on<ParticipantConnectedEvent>((e) {
        if (scoutStatus.value == ScoutStatus.disconnected) {
          _postEvent('$name reconnected');
          scoutStatus.value = ScoutStatus.waiting;
        } else {
          _postEvent('$name joined');
        }
      })
      ..on<ParticipantDisconnectedEvent>((e) {
        scoutStatus.value = ScoutStatus.disconnected;
        remoteVideoTrack.value = null;
        _postEvent('$name disconnected');

        // Only end the session if less than 3 minutes remain.
        // Otherwise leave the room open and wait for the scout to reconnect.
        final remaining = remainingSeconds.value ?? mission.durationInSec;
        if (remaining < _reconnectThreshold.inSeconds) {
          Future.delayed(
            const Duration(seconds: 2),
            () => _onRoomTerminated(null),
          );
        }
      })
      // ── Track subscription ────────────────────────────────────────────────
      ..on<TrackSubscribedEvent>((e) {
        if (e.track is VideoTrack) {
          remoteVideoTrack.value = e.track as VideoTrack;
          scoutStatus.value = ScoutStatus.streaming;
        }
      })
      ..on<TrackUnsubscribedEvent>((e) {
        if (e.track is VideoTrack) {
          remoteVideoTrack.value = null;
          if (scoutStatus.value != ScoutStatus.disconnected) {
            scoutStatus.value = ScoutStatus.waiting;
          }
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

  Future<void> _onRoomTerminated(DisconnectReason? reason) async {
    if (_hasNavigatedAway) return;
    _hasNavigatedAway = true;
    await _teardown();
    Get.offNamed(RateScoutPage.route, arguments: mission);
  }

  // ── Countdown timer ───────────────────────────────────────────────────────

  void _startCountdown() {
    remainingSeconds.value = mission.durationInSec;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isExceeded.value) {
        exceededSeconds.value++;
        return;
      }
      final next = (remainingSeconds.value ?? 0) - 1;
      if (next <= 0) {
        remainingSeconds.value = 0;
        isExceeded.value = true;
      } else {
        remainingSeconds.value = next;
      }
    });
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
          if (scoutStatus.value != ScoutStatus.muted &&
              scoutStatus.value != ScoutStatus.disconnected) {
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
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _participantEventTimer?.cancel();
    _participantEventTimer = null;
    _room.removeListener(_refreshVideoTrack);
    await _roomListener?.dispose();
    _roomListener = null;
    await _room.disconnect();
  }

  String _format(int totalSeconds) {
    final secs = totalSeconds.abs();
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _participantEventTimer?.cancel();
    _room.removeListener(_refreshVideoTrack);
    _roomListener?.dispose();
    _room.disconnect();
    super.onClose();
  }
}
