import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';

class GetMissionByIdUseCase {
  final MissionsRepository repo;

  GetMissionByIdUseCase({required this.repo});

  Future<RepoResponse<MissionEntity?>> call(String missionId) =>
      repo.getMissionById(missionId);
}
