// Unit tests for [LiveChecksController] — the paged, sorted list behind the
// radar's "See all".
//
// The repository is mocked (so [SearchMissionsUseCase] runs for real), and the
// radar, location and FX services are mockito mocks injected through the
// controller's constructor. Pool events are pushed through a plain stream.
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:zuru/core/services/analytics_service/analytics_service.dart';
import 'package:zuru/core/services/analytics_service/providers/provider_interface.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/data/models/mission.model.dart';
import 'package:zuru/modules/missions/domain/entities/mission_page.entity.dart';
import 'package:zuru/modules/missions/domain/usecases/search_missions.usecase.dart';
import 'package:zuru/modules/missions/presentation/controllers/live_checks_controller.dart';

import '../../helpers/test_mocks.mocks.dart';

class _NoopAnalytics implements AnalyticsProvider {
  @override
  Future<void> registerUser(String id) async {}
  @override
  void setUserInfo(Map<String, dynamic> info) {}
  @override
  void setUserProperty({required String prop, dynamic value}) {}
  @override
  void trackEvent({
    required String eventName,
    Map<String, dynamic>? properties,
  }) {}
}

MissionModel _mission(String id) => MissionModel(
  id: id,
  description: '',
  currency: 'KES',
  price: 1000,
  durationInSec: 600,
  address: 'Westlands',
);

RepoResponse<MissionPage> _page(
  List<String> ids, {
  int total = 0,
  MissionPageCursor? next,
}) => Right(
  MissionPage(
    missions: ids.map(_mission).toList(),
    totalCount: total,
    nextCursor: next,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMissionsRepository repo;
  late MockLocationService location;
  late MockFxService fx;
  late MockRadarController radar;
  late StreamController<MissionPoolEvent> pool;
  late Rx<MissionSort> sort;
  late LiveChecksController controller;

  setUpAll(() async {
    Get.testMode = true;
    await AnalyticsService.init(_NoopAnalytics());
  });

  setUp(() {
    repo = MockMissionsRepository();
    location = MockLocationService();
    fx = MockFxService();
    radar = MockRadarController();
    pool = StreamController<MissionPoolEvent>.broadcast();
    sort = MissionSort.nearest.obs;

    when(location.latitude).thenReturn(-1.29);
    when(location.longitude).thenReturn(36.82);
    when(fx.usdToKes).thenReturn(129.5.obs);
    when(radar.sort).thenReturn(sort);
    when(radar.poolEvents).thenAnswer((_) => pool.stream);
    when(radar.setSort(any, source: anyNamed('source'))).thenAnswer((inv) {
      sort.value = inv.positionalArguments.first as MissionSort;
      return Future.value();
    });

    controller = LiveChecksController(
      searchUseCase: SearchMissionsUseCase(repo: repo),
      locationService: location,
      fx: fx,
      radar: radar,
    );
  });

  tearDown(() async {
    controller.onClose();
    await pool.close();
  });

  Future<void> open() async {
    controller.onInit();
    await pumpEventQueue();
  }

  SearchMissionsInput lastInput() =>
      verify(repo.searchMissions(captureAny)).captured.last
          as SearchMissionsInput;

  test('loads the first page from the pinned position and rate', () async {
    when(
      repo.searchMissions(any),
    ).thenAnswer((_) async => _page(['m1', 'm2'], total: 2));

    await open();

    expect(controller.missions.map((m) => m.id), ['m1', 'm2']);
    expect(controller.totalCount.value, 2);
    expect(controller.isLoading.value, isFalse);
    expect(controller.hasMore, isFalse);

    final input = lastInput();
    expect(input.lat, -1.29);
    expect(input.lng, 36.82);
    expect(input.usdToKes, 129.5);
    expect(input.limit, LiveChecksController.pageSize);
    expect(input.cursor, isNull);
  });

  test('loadMore follows the cursor and never lists a mission twice', () async {
    const cursor = MissionPageCursor(sortKey: 20, id: 'm2');
    when(repo.searchMissions(any)).thenAnswer((inv) async {
      final input = inv.positionalArguments.first as SearchMissionsInput;
      return input.cursor == null
          ? _page(['m1', 'm2'], total: 3, next: cursor)
          : _page(['m2', 'm3'], total: 3);
    });

    await open();
    expect(controller.hasMore, isTrue);

    await controller.loadMore();

    expect(controller.missions.map((m) => m.id), ['m1', 'm2', 'm3']);
    expect(lastInput().cursor, same(cursor));
    expect(controller.hasMore, isFalse);
  });

  test('a removal drops the listed mission in place', () async {
    when(
      repo.searchMissions(any),
    ).thenAnswer((_) async => _page(['m1', 'm2'], total: 2));
    await open();

    pool.add(
      const MissionPoolEvent(type: MissionPoolEventType.removed, id: 'm1'),
    );
    await pumpEventQueue();

    expect(controller.missions.map((m) => m.id), ['m2']);
    expect(controller.totalCount.value, 1);
    expect(controller.hasUpdates, isFalse);
    verify(repo.searchMissions(any)).called(1);
  });

  test('additions and edits raise the pill without reshuffling', () async {
    when(
      repo.searchMissions(any),
    ).thenAnswer((_) async => _page(['m1'], total: 1));
    await open();

    pool
      ..add(const MissionPoolEvent(type: MissionPoolEventType.added, id: 'n1'))
      ..add(const MissionPoolEvent(type: MissionPoolEventType.added, id: 'n2'));
    await pumpEventQueue();

    expect(controller.newCount.value, 2);
    expect(controller.hasUpdates, isTrue);
    expect(controller.missions.map((m) => m.id), ['m1']);

    pool.add(
      const MissionPoolEvent(type: MissionPoolEventType.updated, id: 'm1'),
    );
    await pumpEventQueue();
    expect(controller.isStale.value, isTrue);

    await controller.reload();
    expect(controller.hasUpdates, isFalse);
  });

  test('an edit to an unlisted mission is ignored', () async {
    when(
      repo.searchMissions(any),
    ).thenAnswer((_) async => _page(['m1'], total: 1));
    await open();

    pool.add(
      const MissionPoolEvent(type: MissionPoolEventType.updated, id: 'x'),
    );
    await pumpEventQueue();

    expect(controller.hasUpdates, isFalse);
  });

  test('changing the sort saves it on the radar and reloads', () async {
    when(repo.searchMissions(any)).thenAnswer((_) async => _page(['m1']));
    await open();

    await controller.setSort(MissionSort.highestPay);

    verify(radar.setSort(MissionSort.highestPay, source: 'live_checks'));
    expect(lastInput().sort, MissionSort.highestPay);
  });

  test('without a location it explains instead of querying', () async {
    when(location.latitude).thenReturn(null);

    await open();

    expect(controller.error.value, isNotNull);
    expect(controller.isLoading.value, isFalse);
    verifyNever(repo.searchMissions(any));
  });

  test('a failed first page surfaces the error', () async {
    when(
      repo.searchMissions(any),
    ).thenAnswer((_) async => Left(ApiFail('Could not load live checks.')));

    await open();

    expect(controller.error.value, 'Could not load live checks.');
    expect(controller.missions, isEmpty);
  });
}
