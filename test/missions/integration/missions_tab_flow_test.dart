// Integration test: UI → controller → use case → real repository → MOCK datasource.
//
// The real [MissionsTab] page is driven by the real controller/use-case/repository
// stack; only [RemoteMissionsDatasource] is mocked. A row returned by the mocked
// datasource must travel all the way up and render as a mission card.
//
// NOTE: [MissionsTabController.onReady] fetches as soon as the controller is
// registered, so each test stubs the datasource *before* putting the controller.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:zuru/modules/missions/data/repositories_impl/missions_repository_impl.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';
import 'package:zuru/modules/missions/domain/usecases/get_my_missions.usecase.dart';
import 'package:zuru/modules/missions/presentation/controllers/missions_tab_controller.dart';
import 'package:zuru/modules/missions/presentation/pages/missions_tab.dart';

import '../../helpers/test_mocks.mocks.dart';

void main() {
  late MockRemoteMissionsDatasource ds;

  setUp(() {
    Get.testMode = true;
    ds = MockRemoteMissionsDatasource();
    Get.put<MissionsRepository>(MissionsRepositoryImpl(remoteDatasource: ds));
    Get.put<GetMyMissionsUseCase>(
      GetMyMissionsUseCase(repo: Get.find<MissionsRepository>()),
    );
  });

  tearDown(Get.reset);

  /// Registers the controller (which immediately fetches) and renders the page.
  Future<MissionsTabController> pumpTab(WidgetTester tester) async {
    final controller = Get.put(MissionsTabController());
    await tester.pumpWidget(const GetMaterialApp(home: MissionsTab()));
    // Resolve onReady → fetchMissions (real repo adds extra async hops). Avoid
    // pumpAndSettle: the loading shimmer animates indefinitely while loading.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return controller;
  }

  testWidgets('a datasource row renders as a mission card through the full stack',
      (tester) async {
    when(ds.getMyMissions()).thenAnswer(
      (_) async => [
        {
          'id': 'm1',
          'description': 'Verify the venue',
          'currency': 'KES',
          'price': 1500,
          'duration_in_sec': 1800,
          'address': '123 Riverside',
          'status': 'open',
        },
      ],
    );

    final controller = await pumpTab(tester);

    verify(ds.getMyMissions()).called(1);
    // Chain populated the controller…
    expect(controller.isLoading.value, isFalse);
    expect(controller.filteredMissions, hasLength(1));
    // …and the card rendered the mission's description.
    expect(find.text('Verify the venue'), findsOneWidget);
  });

  testWidgets('a datasource failure leaves the list empty (error is handled)',
      (tester) async {
    when(ds.getMyMissions()).thenThrow(Exception('network down'));

    final controller = await pumpTab(tester);

    verify(ds.getMyMissions()).called(1);
    expect(controller.isLoading.value, isFalse);
    expect(controller.filteredMissions, isEmpty);

    // Drain the error snackbar's timer/animation before teardown.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
