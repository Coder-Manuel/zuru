import 'dart:async';

import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';

class GetMyMissionsUseCase implements UseCase<List<MissionEntity>, dynamic> {
  final MissionsRepository repo;
  GetMyMissionsUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<List<MissionEntity>>> call([_]) => repo.getMyMissions();
}
