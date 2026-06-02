import 'dart:async';

import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';

class PostMissionUseCase implements UseCase<MissionEntity, PostMissionInput> {
  final MissionsRepository repo;
  PostMissionUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<MissionEntity>> call(PostMissionInput params) =>
      repo.postMission(params);
}
