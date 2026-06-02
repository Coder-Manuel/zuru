import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';

class AcceptMissionUseCase extends UseCase<void, AcceptMissionInput> {
  final MissionsRepository repo;

  AcceptMissionUseCase({required this.repo});

  @override
  Future<RepoResponse<void>> call(AcceptMissionInput input) =>
      repo.acceptMission(input);
}
