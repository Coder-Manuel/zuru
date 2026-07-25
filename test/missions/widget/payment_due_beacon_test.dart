// Widget test for the client's payment-due beacon on the map tab.
//
// Real [MapsTab] + real [MapsTabController], with the controller's streaming
// use cases backed by a mocked [MissionsRepository]. Covers the point of the
// beacon: it must survive the accept dialog being dismissed, and must only
// appear for accepted-but-unpaid live requests.
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/home/presentation/controllers/maps_tab_controller.dart';
import 'package:zuru/modules/home/presentation/pages/tabs/maps_tab.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/data/models/mission.model.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/entities/session.entity.dart';
import 'package:zuru/modules/missions/domain/usecases/watch_active_missions.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/watch_active_session.usecase.dart';

import '../../helpers/test_mocks.mocks.dart';

MissionModel liveRequest({
  required MissionStatus status,
  String? publishedAt,
  String? acceptedAt,
}) {
  return MissionModel(
    id: 'm1',
    description: 'Show me the balcony view',
    currency: 'KES',
    price: 2400,
    durationInSec: 900,
    address: 'Riverside Drive',
    latitude: -1.2921,
    longitude: 36.8219,
    status: status,
    type: MissionType.liveRequest,
    publishedAt: publishedAt,
    acceptedAt: acceptedAt,
  );
}

void main() {
  late MockMissionsRepository repo;

  /// Registers the controller with [missions] on the active-missions stream.
  void arrange(List<MissionEntity> missions) {
    when(repo.watchActiveMissions()).thenAnswer(
      (_) => Stream.value(Right<ApiFail, List<MissionEntity>>(missions)),
    );
    when(
      repo.watchLiveSession(any),
    ).thenAnswer((_) => const Stream<RepoResponse<SessionEntity>>.empty());
    Get.put<WatchActiveMissionsUseCase>(WatchActiveMissionsUseCase(repo: repo));
    Get.put<WatchActiveSessionUseCase>(WatchActiveSessionUseCase(repo: repo));
    Get.put<MapsTabController>(MapsTabController());
  }

  setUp(() {
    Get.testMode = true;
    repo = MockMissionsRepository();
  });

  tearDown(Get.reset);

  testWidgets('appears for an accepted, unpaid live request', (tester) async {
    arrange([
      liveRequest(
        status: MissionStatus.accepted,
        acceptedAt: DateTime.now().toUtc().toIso8601String(),
      ),
    ]);

    await tester.pumpWidget(const GetMaterialApp(home: MapsTab()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Payment required'), findsOneWidget);
    expect(find.textContaining('KES 2,400'), findsWidgets);
  });

  testWidgets('stays on screen after the accept dialog is dismissed', (
    tester,
  ) async {
    arrange([
      liveRequest(
        status: MissionStatus.accepted,
        acceptedAt: DateTime.now().toUtc().toIso8601String(),
      ),
    ]);

    await tester.pumpWidget(const GetMaterialApp(home: MapsTab()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The accept notice opens by itself…
    expect(find.text('Later'), findsOneWidget);

    // …and dismissing it must not take the beacon with it.
    await tester.tap(find.text('Later'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Later'), findsNothing);
    expect(find.text('Payment required'), findsOneWidget);
  });

  testWidgets('stays hidden while the guide has not accepted yet', (
    tester,
  ) async {
    arrange([liveRequest(status: MissionStatus.requested)]);

    await tester.pumpWidget(const GetMaterialApp(home: MapsTab()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Payment required'), findsNothing);
  });

  testWidgets('stays hidden once the request is paid for', (tester) async {
    arrange([
      liveRequest(
        status: MissionStatus.accepted,
        acceptedAt: DateTime.now().toUtc().toIso8601String(),
        publishedAt: DateTime.now().toUtc().toIso8601String(),
      ),
    ]);

    await tester.pumpWidget(const GetMaterialApp(home: MapsTab()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Payment required'), findsNothing);
  });
}
