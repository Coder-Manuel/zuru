import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';

class WatchActiveMissionUseCase {
  final MissionsRepository repo;

  WatchActiveMissionUseCase({required this.repo});

  Stream<RepoResponse<MissionEntity?>> call(WatchActiveMissionInput input) =>
      repo.watchActiveMission(input);
}
