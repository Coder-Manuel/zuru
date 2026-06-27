import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';

/// Streams the scout's pending client requests — missions a client has
/// targeted at this scout that are awaiting accept/decline.
class WatchScoutRequestsUseCase {
  final MissionsRepository repo;

  WatchScoutRequestsUseCase({required this.repo});

  Stream<RepoResponse<List<MissionEntity>>> call(
    WatchActiveMissionInput input,
  ) => repo.watchScoutRequests(input);
}
