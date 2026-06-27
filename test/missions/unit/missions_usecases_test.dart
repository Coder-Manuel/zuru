// Unit tests for the **missions** module's domain use cases.
//
// Covers both the `Future`-based use cases (post / accept / load) and the
// `Stream`-based ones (the live radar / active-mission / session watchers).
// The [MissionsRepository] is mocked with mockito; entities returned by the
// repo are themselves mocked (they are abstract domain types) so the tests
// stay independent of model-parsing and Supabase.
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/data/models/live_request.input.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/entities/nearby_scout.entity.dart';
import 'package:zuru/modules/missions/domain/entities/session.entity.dart';
import 'package:zuru/modules/missions/domain/usecases/accept_mission.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/create_live_request.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/get_my_missions.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/get_nearby_scouts.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/nearby_missions.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/post_mission.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/update_mission_status.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/watch_active_mission.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/watch_active_missions.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/watch_active_session.usecase.dart';

import '../../helpers/test_mocks.mocks.dart';

void main() {
  late MockMissionsRepository repo;
  late MockMissionEntity mission;

  setUp(() {
    repo = MockMissionsRepository();
    mission = MockMissionEntity();
  });

  final failure = ApiFail('boom');

  // ── Future use cases ────────────────────────────────────────────────────────

  group('PostMissionUseCase', () {
    late PostMissionUseCase useCase;
    final input = PostMissionInput(
      address: '123 Riverside',
      latitude: -1.2921,
      longitude: 36.8219,
      description: 'Verify the venue',
      currency: 'KES',
      price: 1500,
      durationInSec: 1800,
      missionType: MissionType.eventVerification,
    );

    setUp(() => useCase = PostMissionUseCase(repo: repo));

    test('returns the created mission on success', () async {
      when(repo.postMission(input)).thenAnswer((_) async => Right(mission));

      final result = await useCase(input);

      expect(result, Right<ApiFail, MissionEntity>(mission));
      verify(repo.postMission(input)).called(1);
      verifyNoMoreInteractions(repo);
    });

    test('propagates the repository failure', () async {
      when(repo.postMission(input)).thenAnswer((_) async => Left(failure));

      expect((await useCase(input)).isLeft(), isTrue);
      verify(repo.postMission(input)).called(1);
    });
  });

  group('CreateLiveRequestUseCase', () {
    late CreateLiveRequestUseCase useCase;
    const input = LiveRequestInput(
      scoutId: 'scout-1',
      description: 'Live tour of the apartment',
      currency: 'KES',
      price: 2000,
      durationInSec: 900,
    );

    setUp(() => useCase = CreateLiveRequestUseCase(repo: repo));

    test('returns the created live-request mission on success', () async {
      when(
        repo.createLiveRequest(input),
      ).thenAnswer((_) async => Right(mission));

      final result = await useCase(input);

      expect(result, Right<ApiFail, MissionEntity>(mission));
      verify(repo.createLiveRequest(input)).called(1);
    });

    test('propagates the repository failure', () async {
      when(
        repo.createLiveRequest(input),
      ).thenAnswer((_) async => Left(failure));

      expect((await useCase(input)).isLeft(), isTrue);
      verify(repo.createLiveRequest(input)).called(1);
    });
  });

  group('GetMyMissionsUseCase', () {
    late GetMyMissionsUseCase useCase;

    setUp(() => useCase = GetMyMissionsUseCase(repo: repo));

    test('returns the list of missions on success', () async {
      final missions = [mission];
      when(repo.getMyMissions()).thenAnswer((_) async => Right(missions));

      final result = await useCase();

      expect(result, Right<ApiFail, List<MissionEntity>>(missions));
      verify(repo.getMyMissions()).called(1);
    });

    test('propagates the repository failure', () async {
      when(repo.getMyMissions()).thenAnswer((_) async => Left(failure));

      expect((await useCase()).isLeft(), isTrue);
      verify(repo.getMyMissions()).called(1);
    });
  });

  group('GetNearbyScoutsUseCase', () {
    late GetNearbyScoutsUseCase useCase;
    const input = NearbyScoutsInput(
      latitude: -1.2921,
      longitude: 36.8219,
      radiusKm: 7.5,
    );

    setUp(() => useCase = GetNearbyScoutsUseCase(repo: repo));

    test('unpacks the input into named repo params on success', () async {
      final scouts = [MockNearbyScout()];
      when(
        repo.getNearbyScouts(
          latitude: input.latitude,
          longitude: input.longitude,
          radiusKm: input.radiusKm,
        ),
      ).thenAnswer((_) async => Right(scouts));

      final result = await useCase(input);

      expect(result, Right<ApiFail, List<NearbyScout>>(scouts));
      verify(
        repo.getNearbyScouts(
          latitude: input.latitude,
          longitude: input.longitude,
          radiusKm: input.radiusKm,
        ),
      ).called(1);
    });

    test('defaults radiusKm to 5km when omitted', () async {
      const defaulted = NearbyScoutsInput(latitude: 0, longitude: 0);
      when(
        repo.getNearbyScouts(latitude: 0, longitude: 0, radiusKm: 5.0),
      ).thenAnswer((_) async => Right(<NearbyScout>[]));

      await useCase(defaulted);

      verify(
        repo.getNearbyScouts(latitude: 0, longitude: 0, radiusKm: 5.0),
      ).called(1);
    });

    test('propagates the repository failure', () async {
      when(
        repo.getNearbyScouts(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          radiusKm: anyNamed('radiusKm'),
        ),
      ).thenAnswer((_) async => Left(failure));

      expect((await useCase(input)).isLeft(), isTrue);
    });
  });

  group('AcceptMissionUseCase', () {
    late AcceptMissionUseCase useCase;
    const input = AcceptMissionInput(missionId: 'm-1');

    setUp(() => useCase = AcceptMissionUseCase(repo: repo));

    test('resolves Right(void) on success', () async {
      when(repo.acceptMission(input)).thenAnswer((_) async => Right(null));

      final result = await useCase(input);

      expect(result.isRight(), isTrue);
      verify(repo.acceptMission(input)).called(1);
    });

    test('propagates the repository failure', () async {
      when(repo.acceptMission(input)).thenAnswer((_) async => Left(failure));

      expect((await useCase(input)).isLeft(), isTrue);
      verify(repo.acceptMission(input)).called(1);
    });
  });

  group('UpdateMissionStatusUseCase', () {
    late UpdateMissionStatusUseCase useCase;
    const input = UpdateMissionStatusInput(
      missionId: 'm-1',
      status: MissionStatus.completed,
    );

    setUp(() => useCase = UpdateMissionStatusUseCase(repo: repo));

    test('resolves Right(void) on success', () async {
      when(
        repo.updateMissionStatus(input),
      ).thenAnswer((_) async => Right(null));

      final result = await useCase(input);

      expect(result.isRight(), isTrue);
      verify(repo.updateMissionStatus(input)).called(1);
    });

    test('propagates the repository failure', () async {
      when(
        repo.updateMissionStatus(input),
      ).thenAnswer((_) async => Left(failure));

      expect((await useCase(input)).isLeft(), isTrue);
      verify(repo.updateMissionStatus(input)).called(1);
    });
  });

  // ── Stream use cases ────────────────────────────────────────────────────────

  group('NearbyMissionsUseCase', () {
    late NearbyMissionsUseCase useCase;
    const input = NearbyMissionsInput(lat: -1.29, lng: 36.82);

    setUp(() => useCase = NearbyMissionsUseCase(repo: repo));

    test('emits the mission list stream from the repo', () {
      final emission = Right<ApiFail, List<MissionEntity>>([mission]);
      when(
        repo.watchNearbyMissions(input),
      ).thenAnswer((_) => Stream.value(emission));

      expect(useCase(input), emitsInOrder([emission, emitsDone]));
      verify(repo.watchNearbyMissions(input)).called(1);
    });

    test('forwards a failure emission unchanged', () {
      final emission = Left<ApiFail, List<MissionEntity>>(failure);
      when(
        repo.watchNearbyMissions(input),
      ).thenAnswer((_) => Stream.value(emission));

      expect(useCase(input), emits(emission));
    });
  });

  group('WatchActiveMissionsUseCase', () {
    late WatchActiveMissionsUseCase useCase;

    setUp(() => useCase = WatchActiveMissionsUseCase(repo: repo));

    test('emits successive active-mission snapshots', () {
      final first = Right<ApiFail, List<MissionEntity>>([]);
      final second = Right<ApiFail, List<MissionEntity>>([mission]);
      when(
        repo.watchActiveMissions(),
      ).thenAnswer((_) => Stream.fromIterable([first, second]));

      expect(useCase(), emitsInOrder([first, second, emitsDone]));
      verify(repo.watchActiveMissions()).called(1);
    });
  });

  group('WatchActiveMissionUseCase', () {
    late WatchActiveMissionUseCase useCase;
    const input = WatchActiveMissionInput(profileId: 'p-1');

    setUp(() => useCase = WatchActiveMissionUseCase(repo: repo));

    test('emits the active mission, then null when it clears', () {
      final active = Right<ApiFail, MissionEntity?>(mission);
      final cleared = Right<ApiFail, MissionEntity?>(null);
      when(
        repo.watchActiveMission(input),
      ).thenAnswer((_) => Stream.fromIterable([active, cleared]));

      expect(useCase(input), emitsInOrder([active, cleared, emitsDone]));
      verify(repo.watchActiveMission(input)).called(1);
    });
  });

  group('WatchActiveSessionUseCase', () {
    late WatchActiveSessionUseCase useCase;
    const missionIds = ['m-1', 'm-2'];

    setUp(() => useCase = WatchActiveSessionUseCase(repo: repo));

    test('emits the live session stream from the repo', () {
      final session = SessionEntity(id: 's-1', status: SessionStatus.active);
      final emission = Right<ApiFail, SessionEntity>(session);
      when(
        repo.watchLiveSession(missionIds),
      ).thenAnswer((_) => Stream.value(emission));

      expect(useCase(missionIds), emitsInOrder([emission, emitsDone]));
      verify(repo.watchLiveSession(missionIds)).called(1);
    });

    test('forwards a failure emission unchanged', () {
      final emission = Left<ApiFail, SessionEntity>(failure);
      when(
        repo.watchLiveSession(missionIds),
      ).thenAnswer((_) => Stream.value(emission));

      expect(useCase(missionIds), emits(emission));
    });
  });
}
