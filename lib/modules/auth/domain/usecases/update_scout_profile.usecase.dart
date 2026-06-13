import 'dart:async';

import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/auth/data/models/scout_profile.input.dart';
import 'package:zuru/modules/auth/domain/repository/auth_repository.dart';

class UpdateScoutBioUseCase implements UseCase<bool, ScoutProfileInput> {
  final AuthRepository repo;
  UpdateScoutBioUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<bool>> call(ScoutProfileInput params) =>
      repo.updateScoutProfile(params);
}
