import 'dart:async';

import 'package:get/get.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/stream/domain/entities/stream_clock.entity.dart';
import 'package:zuru/modules/stream/domain/usecases/get_stream_clock.usecase.dart';

/// Counts down to the server's deadline for the stream, on both the guide's
/// and the viewer's page.
///
/// The deadline comes from `stream_clock`, so leaving and rejoining picks up
/// the time actually left instead of restarting from the full duration.
/// Until the server has one (the clock starts on the client's first join), a
/// provisional deadline counts down the full duration.
mixin StreamCountdown on GetxController {
  MissionEntity get mission;
  GetStreamClockUseCase get clockUseCase;

  /// Remaining seconds, null until a clock starts.
  final remainingSeconds = Rx<int?>(null);

  /// True once the deadline has passed.
  final isExceeded = false.obs;

  /// Seconds past the deadline.
  final exceededSeconds = 0.obs;

  static const _syncRetryDelay = Duration(seconds: 2);

  DateTime? _deadline;
  bool _hasServerClock = false;
  Timer? _ticker;
  Future<StreamClockEntity?>? _starting;

  /// Whether the countdown runs on the server's deadline yet.
  bool get hasServerClock => _hasServerClock;

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

  /// Reads the server's deadline, trying up to [attempts] times while the
  /// clock has not started (the webhook stamps it just after the client
  /// joins). Returns the last clock read, or null if none could be read.
  Future<StreamClockEntity?> syncClock({int attempts = 1}) async {
    StreamClockEntity? clock;
    for (var i = 0; i < attempts && !isClosed; i++) {
      if (i > 0) await Future.delayed(_syncRetryDelay);
      final result = await clockUseCase(mission.id!);
      clock = result.fold((_) => clock, (c) => c);
      final deadline = clock?.deviceDeadline;
      if (deadline != null) {
        _hasServerClock = true;
        _setDeadline(deadline);
      }
      if (deadline != null || clock?.isOver == true) break;
    }
    return clock;
  }

  /// Syncs to the server, counting down the full duration meanwhile if its
  /// clock has not started yet. Calls while one is running share it.
  Future<StreamClockEntity?> startClock() =>
      _starting ??= _startClock().whenComplete(() => _starting = null);

  Future<StreamClockEntity?> _startClock() async {
    final clock = await syncClock();
    if (_hasServerClock || clock?.isOver == true || isClosed) return clock;
    if (_deadline == null) {
      _setDeadline(
        DateTime.now().add(Duration(seconds: mission.durationInSec)),
      );
    }
    return syncClock(attempts: 5);
  }

  void stopClock() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _setDeadline(DateTime deadline) {
    _deadline = deadline;
    _tick();
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final deadline = _deadline;
    if (deadline == null) return;
    final ms = deadline.difference(DateTime.now()).inMilliseconds;
    if (ms > 0) {
      remainingSeconds.value = (ms / 1000).ceil();
      isExceeded.value = false;
      exceededSeconds.value = 0;
    } else {
      remainingSeconds.value = 0;
      isExceeded.value = true;
      exceededSeconds.value = -ms ~/ 1000;
    }
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
    stopClock();
    super.onClose();
  }
}
