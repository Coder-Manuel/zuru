import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/missions/data/models/live_request.input.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/entities/nearby_scout.entity.dart';
import 'package:zuru/modules/missions/domain/entities/session.entity.dart';

abstract class MissionsRepository {
  // ── Client ────────────────────────────────────────────────────────────────
  Future<RepoResponse<MissionEntity>> postMission(PostMissionInput input);

  /// Creates a live-session request (a [MissionType.liveRequest] mission)
  /// pre-assigned to a scout, optionally scheduled.
  Future<RepoResponse<MissionEntity>> createLiveRequest(LiveRequestInput input);
  Future<RepoResponse<List<MissionEntity>>> getMyMissions();
  Future<RepoResponse<List<NearbyScout>>> getNearbyScouts({
    required double latitude,
    required double longitude,
    required double radiusKm,
  });
  Stream<RepoResponse<List<MissionEntity>>> watchActiveMissions();
  Stream<RepoResponse<SessionEntity>> watchLiveSession(List<String> missions);

  // ── Scout ─────────────────────────────────────────────────────────────────
  Future<RepoResponse<List<MissionEntity>>> getScoutMissions();
  Stream<RepoResponse<List<MissionEntity>>> watchNearbyMissions(
    NearbyMissionsInput input,
  );
  Future<RepoResponse<void>> acceptMission(AcceptMissionInput input);
  Stream<RepoResponse<MissionEntity?>> watchActiveMission(
    WatchActiveMissionInput input,
  );
  Future<RepoResponse<void>> updateMissionStatus(
    UpdateMissionStatusInput input,
  );
}
