import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';

class UpdateMissionStatusUseCase {
  final MissionsRepository repo;

  UpdateMissionStatusUseCase({required this.repo});

  Future<RepoResponse<void>> call(UpdateMissionStatusInput input) =>
      repo.updateMissionStatus(input);
}
