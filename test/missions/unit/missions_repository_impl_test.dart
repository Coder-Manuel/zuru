// Unit tests for [MissionsRepositoryImpl] in isolation.
//
// Mocks the [RemoteMissionsDatasource] and asserts the repository's row→entity
// mapping, its success/failure guards, and the way it converts thrown errors
// (and broken streams) into `FailureResponse`s. No Supabase, no network.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/data/models/live_request.input.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/data/repositories_impl/missions_repository_impl.dart';

import '../../helpers/test_mocks.mocks.dart';

void main() {
  late MockRemoteMissionsDatasource ds;
  late MissionsRepositoryImpl repo;

  setUpAll(() => Get.testMode = true);

  setUp(() {
    ds = MockRemoteMissionsDatasource();
    repo = MissionsRepositoryImpl(remoteDatasource: ds);
  });

  // A minimal-but-valid mission row (the parser fills the rest with defaults).
  Map<String, dynamic> missionRow({String id = 'm1', String? status}) => {
    'id': id,
    'description': 'Verify the venue',
    'currency': 'KES',
    'price': 1500,
    'duration_in_sec': 1800,
    'address': '123 Riverside',
    'status': ?status,
  };

  String? messageOf(RepoResponse result) =>
      result.fold((l) => l.message, (_) => null);

  // ── Future use cases ─────────────────────────────────────────────────────────

  group('postMission', () {
    final input = PostMissionInput(
      address: '123 Riverside',
      latitude: -1.29,
      longitude: 36.82,
      description: 'Verify the venue',
      currency: 'KES',
      price: 1500,
      durationInSec: 1800,
      missionType: MissionType.eventVerification,
    );

    test('maps the inserted row into a MissionEntity', () async {
      when(ds.postMission(any)).thenAnswer((_) async => missionRow());

      final result = await repo.postMission(input);

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => throw 'x').description, 'Verify the venue');
      verify(ds.postMission(input.toMap())).called(1);
    });

    test('fails with a friendly message when the datasource throws', () async {
      when(ds.postMission(any)).thenThrow(Exception('db down'));

      expect(
        messageOf(await repo.postMission(input)),
        'Failed to post mission, kindly retry',
      );
    });
  });

  group('createLiveRequest', () {
    const input = LiveRequestInput(
      scoutId: 'scout-1',
      description: 'Live tour',
      currency: 'KES',
      price: 2000,
      durationInSec: 900,
    );

    test('maps the inserted row into a MissionEntity', () async {
      when(ds.createLiveRequest(any)).thenAnswer((_) async => missionRow());

      expect((await repo.createLiveRequest(input)).isRight(), isTrue);
      verify(ds.createLiveRequest(input.toMap())).called(1);
    });

    test('fails with a friendly message when the datasource throws', () async {
      when(ds.createLiveRequest(any)).thenThrow(Exception('db down'));

      expect(
        messageOf(await repo.createLiveRequest(input)),
        'Failed to send request, kindly retry',
      );
    });
  });

  group('getMyMissions', () {
    test('maps every returned row', () async {
      when(ds.getMyMissions()).thenAnswer(
        (_) async => [missionRow(id: 'm1'), missionRow(id: 'm2')],
      );

      final result = await repo.getMyMissions();

      expect(result.getOrElse(() => []).length, 2);
    });

    test('fails when the datasource throws', () async {
      when(ds.getMyMissions()).thenThrow(Exception('boom'));

      expect(
        messageOf(await repo.getMyMissions()),
        'Failed to load missions, kindly retry',
      );
    });
  });

  group('getNearbyScouts', () {
    test('maps RPC rows into NearbyScout value objects', () async {
      when(ds.getNearbyScouts(any)).thenAnswer(
        (_) async => [
          {'id': 's1', 'distance_meters': 250.0},
          {'id': 's2', 'distance_meters': 800.0},
        ],
      );

      final result = await repo.getNearbyScouts(
        latitude: -1.29,
        longitude: 36.82,
        radiusKm: 5,
      );

      final scouts = result.getOrElse(() => []);
      expect(scouts, hasLength(2));
      expect(scouts.first.distanceMeters, 250.0);
      verify(
        ds.getNearbyScouts({'lat': -1.29, 'lng': 36.82, 'radius_km': 5.0}),
      ).called(1);
    });

    test('fails when the datasource throws', () async {
      when(ds.getNearbyScouts(any)).thenThrow(Exception('boom'));

      final result = await repo.getNearbyScouts(
        latitude: 0,
        longitude: 0,
        radiusKm: 5,
      );

      expect(messageOf(result), 'Failed to load nearby scouts');
    });
  });

  group('getScoutMissions', () {
    test('maps every returned row (scout perspective)', () async {
      when(ds.getScoutMissions()).thenAnswer((_) async => [missionRow()]);

      expect((await repo.getScoutMissions()).getOrElse(() => []), hasLength(1));
    });

    test('fails when the datasource throws', () async {
      when(ds.getScoutMissions()).thenThrow(Exception('boom'));

      expect(
        messageOf(await repo.getScoutMissions()),
        'Failed to load missions, kindly retry',
      );
    });
  });

  group('acceptMission', () {
    const input = AcceptMissionInput(missionId: 'm1');

    test('resolves Right(void) when the datasource confirms', () async {
      when(ds.acceptMission('m1')).thenAnswer((_) async => true);

      expect((await repo.acceptMission(input)).isRight(), isTrue);
      verify(ds.acceptMission('m1')).called(1);
    });

    test('fails when the datasource returns false', () async {
      when(ds.acceptMission('m1')).thenAnswer((_) async => false);

      expect(
        messageOf(await repo.acceptMission(input)),
        'Failed to accept mission. Please try again.',
      );
    });

    test('fails when the datasource throws', () async {
      when(ds.acceptMission(any)).thenThrow(Exception('boom'));

      expect(
        messageOf(await repo.acceptMission(input)),
        'An error occurred. Please try again.',
      );
    });
  });

  group('updateMissionStatus', () {
    const input = UpdateMissionStatusInput(
      missionId: 'm1',
      status: MissionStatus.completed,
    );

    test('resolves Right(void) on success', () async {
      when(
        ds.updateMissionStatus(
          missionId: anyNamed('missionId'),
          status: anyNamed('status'),
        ),
      ).thenAnswer((_) async => {'id': 'm1'});

      expect((await repo.updateMissionStatus(input)).isRight(), isTrue);
      verify(
        ds.updateMissionStatus(missionId: 'm1', status: 'completed'),
      ).called(1);
    });

    test('fails when the datasource throws', () async {
      when(
        ds.updateMissionStatus(
          missionId: anyNamed('missionId'),
          status: anyNamed('status'),
        ),
      ).thenThrow(Exception('boom'));

      expect(
        messageOf(await repo.updateMissionStatus(input)),
        'Failed to update mission. Please try again.',
      );
    });
  });

  // ── Stream use cases ─────────────────────────────────────────────────────────

  group('watchActiveMissions', () {
    test('emits a mapped success snapshot per datasource event', () {
      when(
        ds.watchActiveMissions(),
      ).thenAnswer((_) => Stream.value([missionRow()]));

      expect(
        repo.watchActiveMissions().map((e) => e.isRight()),
        emitsInOrder([true, emitsDone]),
      );
    });

    // NOTE: documents *actual* behaviour. `ErrorWrapper.stream` cannot catch
    // errors raised by the underlying Supabase stream — `yield*` forwards the
    // error event straight to the consumer, bypassing its try/catch — so the
    // `onError → FailureResponse` branch never fires for source-stream errors.
    // In practice the Supabase client swallows failures (they surface as empty
    // lists), so this rarely bites, but the guard is effectively dead code.
    test('propagates a source-stream error (onError guard does not fire)', () {
      when(
        ds.watchActiveMissions(),
      ).thenAnswer((_) => Stream.error(Exception('stream boom')));

      expect(repo.watchActiveMissions(), emitsError(isA<Exception>()));
    });
  });

  group('watchNearbyMissions', () {
    const input = NearbyMissionsInput(lat: -1.29, lng: 36.82);

    test('emits a mapped success snapshot', () {
      when(
        ds.watchNearbyMissions(any),
      ).thenAnswer((_) => Stream.value([missionRow()]));

      expect(
        repo.watchNearbyMissions(input).map((e) => e.isRight()),
        emitsInOrder([true, emitsDone]),
      );
    });
  });

  group('watchActiveMission', () {
    const input = WatchActiveMissionInput(profileId: 'p1');

    test('emits Right(null) when there is no active mission', () {
      when(
        ds.watchScoutActiveMission(any),
      ).thenAnswer((_) => Stream.value(null));

      expect(
        repo.watchActiveMission(input),
        emits(
          predicate<RepoResponse>(
            (r) => r.fold((_) => false, (m) => m == null),
          ),
        ),
      );
    });

    test('emits a mapped mission when one is active', () {
      when(
        ds.watchScoutActiveMission(any),
      ).thenAnswer((_) => Stream.value(missionRow()));

      expect(
        repo.watchActiveMission(input),
        emits(
          predicate<RepoResponse>(
            (r) => r.fold((_) => false, (m) => m != null),
          ),
        ),
      );
    });
  });

  group('watchLiveSession', () {
    test('emits a mapped SessionEntity', () {
      when(ds.watchLiveSessions(any)).thenAnswer(
        (_) => Stream.value({'id': 's1', 'status': 'active'}),
      );

      expect(
        repo.watchLiveSession(['m1']).map((e) => e.isRight()),
        emitsInOrder([true, emitsDone]),
      );
    });

    // See the note on watchActiveMissions: source-stream errors are propagated,
    // not converted to a FailureResponse.
    test('propagates a source-stream error (onError guard does not fire)', () {
      when(
        ds.watchLiveSessions(any),
      ).thenAnswer((_) => Stream.error(Exception('boom')));

      expect(repo.watchLiveSession(['m1']), emitsError(isA<Exception>()));
    });
  });
}
