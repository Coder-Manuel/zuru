import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';

class DeclineMissionUseCase {
  final MissionsRepository repo;

  DeclineMissionUseCase({required this.repo});

  Future<RepoResponse<void>> call(DeclineMissionInput input) =>
      repo.declineMission(input);
}
