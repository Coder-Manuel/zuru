import 'dart:async';

import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/missions/data/models/live_request.input.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';

class CreateLiveRequestUseCase
    implements UseCase<MissionEntity, LiveRequestInput> {
  final MissionsRepository repo;
  CreateLiveRequestUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<MissionEntity>> call(LiveRequestInput params) =>
      repo.createLiveRequest(params);
}
