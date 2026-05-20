import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/entities/nearby_scout.entity.dart';
import 'package:zuru/modules/missions/domain/entities/session.entity.dart';

abstract class MissionsRepository {
  Future<RepoResponse<MissionEntity>> postMission(PostMissionInput input);
  Future<RepoResponse<List<MissionEntity>>> getMyMissions();
  Future<RepoResponse<List<NearbyScout>>> getNearbyScouts({
    required double latitude,
    required double longitude,
    required double radiusKm,
  });

  /// Real-time stream of the current user's missions.
  ///
  /// Supabase RLS ensures only the authenticated user's rows are delivered.
  /// Rows are emitted in full on every insert / update / delete.
  Stream<RepoResponse<List<MissionEntity>>> watchActiveMissions();
  Stream<RepoResponse<SessionEntity>> watchLiveSession(List<String> missions);
}
