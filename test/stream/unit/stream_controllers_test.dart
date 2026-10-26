// Unit tests for the stream controllers' room lifecycle (BUG-006 follow-up).
//
// Each StreamPage / JoinStreamPage creates its own controller, so closing one
// must release its LiveKit room completely: disconnect AND dispose (dispose is
// what stops the engine's timers). The room is faked; the backend fails so
// initialize() never connects.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/missions/data/models/mission.model.dart';
import 'package:zuru/modules/stream/data/models/stream.inputs.dart';
import 'package:zuru/modules/stream/domain/entities/livekit_session.entity.dart';
import 'package:zuru/modules/stream/domain/repository/stream_repository.dart';
import 'package:zuru/modules/stream/domain/usecases/go_live.usecase.dart';
import 'package:zuru/modules/stream/domain/usecases/join_stream.usecase.dart';
import 'package:zuru/modules/stream/presentation/controllers/join_stream_controller.dart';
import 'package:zuru/modules/stream/presentation/controllers/live_stream_controller.dart';

class _OfflineStreamRepository implements StreamRepository {
  @override
  Future<RepoResponse<LiveKitSessionEntity>> joinStream(
    String missionId,
  ) async => FailureResponse('offline');

  @override
  Future<RepoResponse<LiveKitSessionEntity>> goLive(
    InitStreamInput input,
  ) async => FailureResponse('offline');
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

  late StreamRepository repo;

  setUp(() {
    Get.testMode = true;
    repo = _OfflineStreamRepository();
  });

  tearDown(Get.reset);

  /// Lets the disconnect → dispose chain run.
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  test(
    'closing a viewer controller disconnects and disposes its room',
    () async {
      final room = _FakeRoom();
      final ctrl = Get.put(
        JoinStreamController(
          joinStreamUseCase: JoinStreamUseCase(repo: repo),
          room: room,
        ),
        tag: 'page-1',
      );

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
      final ctrl = Get.put(
        LiveStreamController(
          goLiveUseCase: GoLiveUseCase(repo: repo),
          room: room,
        ),
        tag: 'page-1',
      );

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
      Get.put(
        JoinStreamController(
          joinStreamUseCase: JoinStreamUseCase(repo: repo),
          room: room,
        ),
        tag: 'page-1',
      );

      await Get.delete<JoinStreamController>(tag: 'page-1');
      await flush();

      expect(room.disconnects, 0);
      expect(room.disposes, 1);
    },
  );

  test('closing one page leaves another page\'s session untouched', () async {
    final oldRoom = _FakeRoom();
    final newRoom = _FakeRoom();
    Get.put(
      JoinStreamController(
        joinStreamUseCase: JoinStreamUseCase(repo: repo),
        room: oldRoom,
      ),
      tag: 'old',
    );
    final newer = Get.put(
      JoinStreamController(
        joinStreamUseCase: JoinStreamUseCase(repo: repo),
        room: newRoom,
      ),
      tag: 'new',
    );

    // The old page is disposed after the new one opened.
    await Get.delete<JoinStreamController>(tag: 'old');
    await flush();

    expect(oldRoom.disposes, 1);
    expect(newRoom.disconnects, 0);
    expect(newRoom.disposes, 0);
    expect(newer.isClosed, isFalse);
  });
}
