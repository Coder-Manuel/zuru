// On-device checks for BUG-006 and the per-page stream controllers, with the
// real wakelock plugin and real LiveKit rooms. The backend is faked to fail,
// so the pages settle on their error state without joining a room.
//
//   fvm flutter test integration_test/stream_pages_check.dart -d <id>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/missions/data/models/mission.model.dart';
import 'package:zuru/modules/stream/data/models/stream.inputs.dart';
import 'package:zuru/modules/stream/domain/entities/livekit_session.entity.dart';
import 'package:zuru/modules/stream/domain/repository/stream_repository.dart';
import 'package:zuru/modules/stream/domain/usecases/go_live.usecase.dart';
import 'package:zuru/modules/stream/domain/usecases/join_stream.usecase.dart';
import 'package:zuru/modules/stream/presentation/controllers/join_stream_controller.dart';
import 'package:zuru/modules/stream/presentation/controllers/live_stream_controller.dart';
import 'package:zuru/modules/stream/presentation/pages/join_stream_page.dart';
import 'package:zuru/modules/stream/presentation/pages/stream_page.dart';

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

final _mission = MissionModel(
  id: 'm1',
  description: 'Check the gate',
  currency: 'KES',
  price: 500,
  durationInSec: 600,
  address: 'Mkungu Cl, Nairobi',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final repo = _OfflineStreamRepository();
    Get.put(JoinStreamUseCase(repo: repo));
    Get.put(GoLiveUseCase(repo: repo));
    await WakelockPlus.disable();
  });

  tearDown(Get.reset);

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Scaffold()),
          GetPage(name: '/join', page: () => const JoinStreamPage()),
          GetPage(name: '/live', page: () => const StreamPage()),
        ],
      ),
    );
  }

  /// The pages animate forever, so pumpAndSettle would never return.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  String tagOf(WidgetTester tester, Finder page) =>
      identityHashCode(tester.state(page)).toString();

  testWidgets('viewer page keeps the screen on only while open', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(await WakelockPlus.enabled, isFalse);

    Get.toNamed('/join', arguments: _mission);
    await settle(tester);

    final tag = tagOf(tester, find.byType(JoinStreamPage));
    expect(Get.isRegistered<JoinStreamController>(tag: tag), isTrue);
    expect(await WakelockPlus.enabled, isTrue);

    Get.back();
    await settle(tester);

    expect(Get.isRegistered<JoinStreamController>(tag: tag), isFalse);
    expect(await WakelockPlus.enabled, isFalse);
  });

  testWidgets('guide page keeps the screen on only while open', (tester) async {
    await pumpApp(tester);

    Get.toNamed('/live', arguments: _mission);
    await settle(tester);

    final tag = tagOf(tester, find.byType(StreamPage));
    expect(Get.isRegistered<LiveStreamController>(tag: tag), isTrue);
    expect(await WakelockPlus.enabled, isTrue);

    Get.back();
    await settle(tester);

    expect(Get.isRegistered<LiveStreamController>(tag: tag), isFalse);
    expect(await WakelockPlus.enabled, isFalse);
  });

  testWidgets('the wakelock comes back after the OS drops it', (tester) async {
    await pumpApp(tester);
    Get.toNamed('/join', arguments: _mission);
    await settle(tester);
    expect(await WakelockPlus.enabled, isTrue);

    // What the OS may do while the app is away.
    await WakelockPlus.disable();
    expect(await WakelockPlus.enabled, isFalse);

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await settle(tester);

    expect(await WakelockPlus.enabled, isTrue);
    Get.back();
    await settle(tester);
  });

  testWidgets('re-entering a live keeps the new session and the wakelock', (
    tester,
  ) async {
    await pumpApp(tester);
    Get.toNamed('/join', arguments: _mission);
    await settle(tester);
    final oldTag = tagOf(tester, find.byType(JoinStreamPage));

    // The old page is disposed only after the new one has started.
    Get.offNamed('/join', arguments: _mission, preventDuplicates: false);
    await settle(tester);

    final newTag = tagOf(tester, find.byType(JoinStreamPage));
    expect(newTag, isNot(oldTag));
    expect(Get.isRegistered<JoinStreamController>(tag: oldTag), isFalse);
    expect(Get.isRegistered<JoinStreamController>(tag: newTag), isTrue);
    expect(Get.find<JoinStreamController>(tag: newTag).isClosed, isFalse);
    expect(await WakelockPlus.enabled, isTrue);

    Get.back();
    await settle(tester);
    expect(await WakelockPlus.enabled, isFalse);
  });
}
