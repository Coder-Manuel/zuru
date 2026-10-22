import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/utils/error_wrapper.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/data/models/live_request.input.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/data/models/mission.model.dart';
import 'package:zuru/modules/missions/data/models/nearby_scout.model.dart';
import 'package:zuru/modules/missions/data/models/session.model.dart';
import 'package:zuru/modules/missions/data/sources/remote_missions_datasource.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/entities/mission_page.entity.dart';
import 'package:zuru/modules/missions/domain/entities/nearby_scout.entity.dart';
import 'package:zuru/modules/missions/domain/entities/session.entity.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';

class MissionsRepositoryImpl extends MissionsRepository {
  final _library = 'Missions Repository';
  final RemoteMissionsDatasource remoteDatasource;

  MissionsRepositoryImpl({required this.remoteDatasource});

  @override
  Future<RepoResponse<MissionEntity>> postMission(
    PostMissionInput input,
  ) async {
    final response = await ErrorWrapper.async<RepoResponse<MissionEntity>>(
      () async {
        final data = await remoteDatasource.postMission(input.toMap());
        return SuccessResponse(MissionModel.fromMap(data));
      },
      onError: (_) =>
          FailureResponse('Failed to post live check, kindly retry'),
      library: _library,
      description: 'while posting mission',
    );
    return response!;
  }

  @override
  Future<RepoResponse<MissionEntity>> createLiveRequest(
    LiveRequestInput input,
  ) async {
    final response = await ErrorWrapper.async<RepoResponse<MissionEntity>>(
      () async {
        final data = await remoteDatasource.createLiveRequest(input.toMap());
        return SuccessResponse(MissionModel.fromMap(data));
      },
      onError: (_) => FailureResponse('Failed to send request, kindly retry'),
      library: _library,
      description: 'while creating live request',
    );
    return response!;
  }

  @override
  Future<RepoResponse<List<MissionEntity>>> getMyMissions() async {
    final response =
        await ErrorWrapper.async<RepoResponse<List<MissionEntity>>>(
          () async {
            final data = await remoteDatasource.getMyMissions();
            return SuccessResponse(data.map(MissionModel.fromMap).toList());
          },
          onError: (_) =>
              FailureResponse('Failed to load live checks, kindly retry'),
          library: _library,
          description: 'while loading missions',
        );
    return response!;
  }

  @override
  Stream<RepoResponse<List<MissionEntity>>> watchActiveMissions() async* {
    yield* ErrorWrapper.stream<RepoResponse<List<MissionEntity>>>(
      () async* {
        await for (final rows in remoteDatasource.watchActiveMissions()) {
          yield SuccessResponse(
            rows.map((row) => MissionModel.fromMap(row)).toList(),
          );
        }
      },
      onError: (_) => FailureResponse('An error occurred. Kindly retry.'),
      library: _library,
      description: 'while streaming active missions',
    );
  }

  @override
  Future<RepoResponse<List<NearbyScout>>> getNearbyScouts({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final response = await ErrorWrapper.async<RepoResponse<List<NearbyScout>>>(
      () async {
        final data = await remoteDatasource.getNearbyScouts({
          'lat': latitude,
          'lng': longitude,
          'radius_km': radiusKm,
        });
        return SuccessResponse(data.map(NearbyScoutModel.fromMap).toList());
      },
      onError: (_) => FailureResponse('Failed to load nearby guides'),
      library: _library,
      description: 'while fetching nearby scouts',
    );
    return response!;
  }

  @override
  Stream<RepoResponse<SessionEntity>> watchLiveSession(
    List<String> missions,
  ) async* {
    yield* ErrorWrapper.stream<RepoResponse<SessionEntity>>(
      () async* {
        await for (final row in remoteDatasource.watchLiveSessions(missions)) {
          yield SuccessResponse(SessionModel.fromMap(row));
        }
      },
      onError: (_) => FailureResponse('Failed to watch sessions.'),
      library: _library,
      description: 'while streaming sessions',
    );
  }

  // ── Scout ─────────────────────────────────────────────────────────────────

  @override
  Future<RepoResponse<List<MissionEntity>>> getScoutMissions() async {
    final response =
        await ErrorWrapper.async<RepoResponse<List<MissionEntity>>>(
          () async {
            final data = await remoteDatasource.getScoutMissions();
            return SuccessResponse(
              data.map((r) => MissionModel.fromScoutMap(r)).toList(),
            );
          },
          onError: (_) =>
              FailureResponse('Failed to load live checks, kindly retry'),
          library: _library,
          description: 'while loading scout missions',
        );
    return response!;
  }

  @override
  Future<RepoResponse<MissionPage>> searchMissions(
    SearchMissionsInput input,
  ) async {
    final response = await ErrorWrapper.async<RepoResponse<MissionPage>>(
      () async {
        final rows = await remoteDatasource.searchMissions(input.toMap());
        final missions = rows
            .map(
              (row) => MissionModel.fromScoutMap(
                row,
                scoutLat: input.lat,
                scoutLng: input.lng,
              ),
            )
            .toList();

        // A full page means there may be more; the last row is the cursor.
        MissionPageCursor? next;
        if (rows.length >= input.limit && rows.isNotEmpty) {
          final last = rows.last;
          final key = (last['sort_key'] as num?)?.toDouble();
          final id = last['id']?.toString();
          if (key != null && id != null) {
            next = MissionPageCursor(sortKey: key, id: id);
          }
        }

        return SuccessResponse(
          MissionPage(
            missions: missions,
            totalCount: rows.isEmpty
                ? 0
                : (rows.first['total_count'] as num?)?.toInt() ??
                      missions.length,
            nextCursor: next,
          ),
        );
      },
      onError: (_) => FailureResponse('Could not load live checks. Retry.'),
      library: _library,
      description: 'while searching the mission pool',
    );
    return response!;
  }

  @override
  Stream<RepoResponse<MissionPoolEvent>> watchMissionPool() async* {
    yield* ErrorWrapper.stream<RepoResponse<MissionPoolEvent>>(
      () async* {
        await for (final raw in remoteDatasource.watchMissionPool()) {
          final type = MissionPoolEventType.fromApi(raw['event']?.toString());
          final id = raw['id']?.toString();
          if (type == null || id == null) continue;
          yield SuccessResponse(
            MissionPoolEvent(
              type: type,
              id: id,
              latitude: (raw['lat'] as num?)?.toDouble(),
              longitude: (raw['lng'] as num?)?.toDouble(),
            ),
          );
        }
      },
      onError: (_) => FailureResponse('Live check updates were interrupted.'),
      library: _library,
      description: 'while watching the mission pool',
    );
  }

  @override
  Future<RepoResponse<void>> acceptMission(AcceptMissionInput input) async {
    final response = await ErrorWrapper.async<RepoResponse<void>>(
      () async {
        final res = await remoteDatasource.acceptMission(input.missionId);
        if (!res) {
          return FailureResponse(
            'Failed to accept live check. Please try again.',
          );
        }
        return SuccessResponse(null);
      },
      onError: (_) => FailureResponse('An error occurred. Please try again.'),
      library: _library,
      description: 'while accepting mission',
    );
    return response!;
  }

  @override
  Stream<RepoResponse<MissionEntity?>> watchActiveMission(
    WatchActiveMissionInput input,
  ) async* {
    yield* ErrorWrapper.stream<RepoResponse<MissionEntity?>>(
      () async* {
        await for (final row in remoteDatasource.watchScoutActiveMission(
          input.profileId,
        )) {
          if (row == null) {
            yield SuccessResponse(null);
          } else {
            yield SuccessResponse(
              MissionModel.fromScoutMap(
                row,
                scoutLat: input.scoutLat,
                scoutLng: input.scoutLng,
              ),
            );
          }
        }
      },
      onError: (_) => FailureResponse('Failed to watch active live check.'),
      library: _library,
      description: 'while streaming active mission',
    );
  }

  @override
  Stream<RepoResponse<List<MissionEntity>>> watchScoutRequests(
    WatchActiveMissionInput input,
  ) async* {
    yield* ErrorWrapper.stream<RepoResponse<List<MissionEntity>>>(
      () async* {
        await for (final rows in remoteDatasource.watchScoutRequests(
          input.profileId,
        )) {
          yield SuccessResponse(
            rows
                .map(
                  (row) => MissionModel.fromScoutMap(
                    row,
                    scoutLat: input.scoutLat,
                    scoutLng: input.scoutLng,
                  ),
                )
                .toList(),
          );
        }
      },
      onError: (_) => FailureResponse('Failed to watch requests.'),
      library: _library,
      description: 'while streaming scout requests',
    );
  }

  @override
  Future<RepoResponse<void>> updateMissionStatus(
    UpdateMissionStatusInput input,
  ) async {
    final ok = await ErrorWrapper.async<bool>(
      () async {
        await remoteDatasource.updateMissionStatus(
          missionId: input.missionId,
          values: {'status': input.status.name},
        );
        return true;
      },
      onError: (_) => false,
      library: _library,
      description: 'while updating mission status',
    );
    if (ok != true) {
      return FailureResponse('Failed to update live check. Please try again.');
    }
    return SuccessResponse(null);
  }

  @override
  Future<RepoResponse<MissionEntity?>> getMissionById(String missionId) async {
    final response = await ErrorWrapper.async<RepoResponse<MissionEntity?>>(
      () async {
        final row = await remoteDatasource.getMissionById(missionId);
        return SuccessResponse(row == null ? null : MissionModel.fromMap(row));
      },
      onError: (_) => FailureResponse('Could not load the live check.'),
      library: _library,
      description: 'while loading mission by id',
    );
    return response!;
  }

  @override
  Future<RepoResponse<DeclineOutcome>> declineMission(
    DeclineMissionInput input,
  ) async {
    final missionId = input.mission.id;
    if (missionId == null || missionId.isEmpty) {
      return FailureResponse('Failed to decline live check. Please try again.');
    }
    final outcome = await ErrorWrapper.async<DeclineOutcome>(
      () async => DeclineOutcome.fromApi(
        await remoteDatasource.declineMission(missionId),
      ),
      onError: (_) => null,
      library: _library,
      description: 'while declining mission',
    );
    if (outcome == null) {
      return FailureResponse('Failed to decline live check. Please try again.');
    }
    return SuccessResponse(outcome);
  }
}
