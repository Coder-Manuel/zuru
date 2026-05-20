import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';

/// Stream use-case — not extending [UseCase] because the return type is
/// [Stream] rather than [FutureOr].
class NearbyMissionsUseCase
    extends StreamUseCase<List<MissionEntity>, NearbyMissionsInput> {
  final MissionsRepository repo;

  NearbyMissionsUseCase({required this.repo});

  @override
  Stream<RepoResponse<List<MissionEntity>>> call(NearbyMissionsInput input) {
    return repo.watchNearbyMissions(input);
  }
}
