import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/entities/mission_page.entity.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';

class SearchMissionsUseCase extends UseCase<MissionPage, SearchMissionsInput> {
  final MissionsRepository repo;

  SearchMissionsUseCase({required this.repo});

  @override
  Future<RepoResponse<MissionPage>> call(SearchMissionsInput params) {
    return repo.searchMissions(params);
  }
}
