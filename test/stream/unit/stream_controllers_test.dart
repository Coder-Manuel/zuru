// Unit tests for the stream controllers.
//
// Room lifecycle (BUG-006 follow-up): each StreamPage / JoinStreamPage creates
// its own controller, so closing one must release its LiveKit room
// completely: disconnect AND dispose (dispose is what stops the engine's
// timers). The room is faked; go-live fails so initialize() never connects.
//
// Stream clock (BUG-008): the countdown runs on the server's deadline, so a
// rejoin shows the time actually left.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/missions/data/models/mission.model.dart';
import 'package:zuru/modules/stream/data/models/stream.inputs.dart';
import 'package:zuru/modules/stream/data/models/stream_clock.model.dart';
import 'package:zuru/modules/stream/domain/entities/livekit_session.entity.dart';
import 'package:zuru/modules/stream/domain/entities/stream_clock.entity.dart';
import 'package:zuru/modules/stream/domain/repository/stream_repository.dart';
import 'package:zuru/modules/stream/domain/usecases/end_session.usecase.dart';
import 'package:zuru/modules/stream/domain/usecases/get_stream_clock.usecase.dart';
import 'package:zuru/modules/stream/domain/usecases/go_live.usecase.dart';
import 'package:zuru/modules/stream/domain/usecases/join_stream.usecase.dart';
import 'package:zuru/modules/stream/presentation/controllers/join_stream_controller.dart';
import 'package:zuru/modules/stream/presentation/controllers/live_stream_controller.dart';
import 'package:zuru/modules/stream/presentation/services/reconnect_grace.dart';

class _OfflineStreamRepository implements StreamRepository {
  /// Builds what `stream_clock` answers, at the time it is read; null fails
  /// like being offline.
  StreamClockEntity Function()? clock;

  @override
  Future<RepoResponse<LiveKitSessionEntity>> joinStream(
    String missionId,
  ) async => FailureResponse('offline');

  @override
  Future<RepoResponse<LiveKitSessionEntity>> goLive(
    InitStreamInput input,
  ) async => FailureResponse('offline');

  @override
  Future<RepoResponse<StreamClockEntity>> getStreamClock(
    String missionId,
  ) async {
    final c = clock;
    return c == null ? FailureResponse('offline') : SuccessResponse(c());
  }

  @override
  Future<RepoResponse<bool>> endSession(String missionId) async =>
      FailureResponse('offline');
}

/// A `stream_clock` answer [left] before the deadline, from a server whose
/// clock is [skew] ahead of this device's.
StreamClockEntity _clock(
  Duration left, {
  Duration skew = Duration.zero,
  String status = 'live',
}) {
  final now = DateTime.now();
  final serverNow = now.add(skew);
  return StreamClockModel(
    status: status,
    endsAt: serverNow.add(left),
    serverNow: serverNow,
    receivedAt: now,
  );
}

class _FakeRoom implements Room {
  _FakeRoom({this.connectionState = ConnectionState.connected});

  @override
  final ConnectionState connectionState;

  int disconnects = 0;
  int disposes = 0;

  @override
  Future<void> disconnect() async => disconnects++;

  @override
  Future<bool> dispose() async {
    disposes++;
    return true;
  }

  @override
  void removeListener(VoidCallback listener) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

final _mission = MissionModel(
  id: 'm1',
  description: 'Check the gate',
  currency: 'KES',
  price: 500,
  durationInSec: 600,
  address: 'Mkungu Cl, Nairobi',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _OfflineStreamRepository repo;

  setUp(() {
    Get.testMode = true;
    repo = _OfflineStreamRepository();
  });

  JoinStreamController viewer(Room room, {String tag = 'page-1'}) => Get.put(
    JoinStreamController(
      joinStreamUseCase: JoinStreamUseCase(repo: repo),
      clockUseCase: GetStreamClockUseCase(repo: repo),
      room: room,
    ),
    tag: tag,
  );

  LiveStreamController guide(Room room) => Get.put(
    LiveStreamController(
      goLiveUseCase: GoLiveUseCase(repo: repo),
      endSessionUseCase: EndSessionUseCase(repo: repo),
      clockUseCase: GetStreamClockUseCase(repo: repo),
      room: room,
    ),
    tag: 'page-1',
  );

  tearDown(Get.reset);

  /// Lets the disconnect → dispose chain run.
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  test(
    'closing a viewer controller disconnects and disposes its room',
    () async {
      final room = _FakeRoom();
      final ctrl = viewer(room);

      await ctrl.initialize(_mission);
      expect(ctrl.hasError.value, isTrue);

      await Get.delete<JoinStreamController>(tag: 'page-1');
      await flush();

      expect(room.disconnects, 1);
      expect(room.disposes, 1);
    },
  );

  test(
    'closing a guide controller disconnects and disposes its room',
    () async {
      final room = _FakeRoom();
      final ctrl = guide(room);

      await ctrl.initialize(_mission);
      expect(ctrl.hasError.value, isTrue);

      await Get.delete<LiveStreamController>(tag: 'page-1');
      await flush();

      expect(room.disconnects, 1);
      expect(room.disposes, 1);
    },
  );

  test(
    'a room that never connected is disposed without disconnecting',
    () async {
      // Disconnecting it would wait for an event that never comes and time out.
      final room = _FakeRoom(connectionState: ConnectionState.disconnected);
      viewer(room);

      await Get.delete<JoinStreamController>(tag: 'page-1');
      await flush();

      expect(room.disconnects, 0);
      expect(room.disposes, 1);
    },
  );

  test('closing one page leaves another page\'s session untouched', () async {
    final oldRoom = _FakeRoom();
    final newRoom = _FakeRoom();
    viewer(oldRoom, tag: 'old');
    final newer = viewer(newRoom, tag: 'new');

    // The old page is disposed after the new one opened.
    await Get.delete<JoinStreamController>(tag: 'old');
    await flush();

    expect(oldRoom.disposes, 1);
    expect(newRoom.disconnects, 0);
    expect(newRoom.disposes, 0);
    expect(newer.isClosed, isFalse);
  });

  group('stream clock', () {
    test('a rejoin counts down the time left, not the full duration', () async {
      // The mission is 600 s; 100 s are left on the server.
      repo.clock = () => _clock(const Duration(seconds: 100));
      final ctrl = viewer(_FakeRoom())..mission = _mission;

      await ctrl.startClock();

      expect(ctrl.hasServerClock, isTrue);
      expect(ctrl.remainingSeconds.value, inInclusiveRange(99, 100));
      expect(ctrl.timerLabel, anyOf('01:40', '01:39'));
    });

    test('a device clock that is off does not change the time left', () async {
      repo.clock = () =>
          _clock(const Duration(seconds: 100), skew: const Duration(hours: 1));
      final ctrl = guide(_FakeRoom())..mission = _mission;

      await ctrl.syncClock();

      expect(ctrl.remainingSeconds.value, inInclusiveRange(99, 100));
    });

    test('past the deadline the timer shows overtime', () async {
      repo.clock = () => _clock(const Duration(seconds: -42));
      final ctrl = viewer(_FakeRoom())..mission = _mission;

      await ctrl.syncClock();

      expect(ctrl.isExceeded.value, isTrue);
      expect(ctrl.exceededSeconds.value, inInclusiveRange(42, 43));
      expect(ctrl.timerLabel, startsWith('+00:4'));
    });

    test(
      'offline, the full duration counts down until the server answers',
      () async {
        final ctrl = viewer(_FakeRoom())..mission = _mission;

        // One attempt is enough to see the provisional clock.
        final pending = ctrl.startClock();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(ctrl.hasServerClock, isFalse);
        expect(ctrl.remainingSeconds.value, inInclusiveRange(599, 600));

        // The server's clock starts; the next retry picks it up.
        repo.clock = () => _clock(const Duration(seconds: 590));
        await pending;
        expect(ctrl.hasServerClock, isTrue);
        expect(ctrl.remainingSeconds.value, inInclusiveRange(589, 590));
      },
    );
  });

  group('reconnect grace', () {
    test('counts 30 seconds and stops when cancelled', () {
      final grace = ReconnectGrace();
      var expired = false;

      grace.start(() => expired = true);
      expect(grace.isRunning, isTrue);
      expect(grace.secondsLeft.value, 30);

      // A second drop while counting does not restart it.
      grace.secondsLeft.value = 12;
      grace.start(() => expired = true);
      expect(grace.secondsLeft.value, 12);

      grace.cancel();
      expect(grace.isRunning, isFalse);
      expect(grace.secondsLeft.value, isNull);
      expect(expired, isFalse);
    });
  });
}
