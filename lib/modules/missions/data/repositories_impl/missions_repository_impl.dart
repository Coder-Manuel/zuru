import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/utils/error_wrapper.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/data/models/mission.model.dart';
import 'package:zuru/modules/missions/data/models/nearby_scout.model.dart';
import 'package:zuru/modules/missions/data/models/session.model.dart';
import 'package:zuru/modules/missions/data/sources/remote_missions_datasource.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
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
      onError: (_) => FailureResponse('Failed to post mission, kindly retry'),
      library: _library,
      description: 'while posting mission',
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
              FailureResponse('Failed to load missions, kindly retry'),
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
      onError: (_) => FailureResponse('Failed to load nearby scouts'),
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
}
