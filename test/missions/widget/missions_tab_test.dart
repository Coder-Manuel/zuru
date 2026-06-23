// Widget test for [MissionsTab] in isolation.
//
// Real page + real [MissionsTabController], but the controller's use case is
// backed by a *mocked* [MissionsRepository]. We assert the page chrome renders
// and that the empty state appears when the repo yields no missions — without a
// real datasource.
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/usecases/get_my_missions.usecase.dart';
import 'package:zuru/modules/missions/presentation/controllers/missions_tab_controller.dart';
import 'package:zuru/modules/missions/presentation/pages/missions_tab.dart';

import '../../helpers/test_mocks.mocks.dart';

void main() {
  late MockMissionsRepository repo;

  setUp(() {
    Get.testMode = true;
    repo = MockMissionsRepository();
    // Stub before the controller is created — its onReady fetches immediately.
    when(repo.getMyMissions())
        .thenAnswer((_) async => Right<ApiFail, List<MissionEntity>>([]));
    Get.put<GetMyMissionsUseCase>(GetMyMissionsUseCase(repo: repo));
    Get.put<MissionsTabController>(MissionsTabController());
  });

  tearDown(Get.reset);

  testWidgets('renders the header and filter chips', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: MissionsTab()));
    // Let onReady → fetchMissions resolve (avoid pumpAndSettle: the loading
    // shimmer animates indefinitely while isLoading is true).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Missions'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no missions',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: MissionsTab()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final controller = Get.find<MissionsTabController>();
    expect(controller.isLoading.value, isFalse);
    expect(controller.filteredMissions, isEmpty);
  });
}
