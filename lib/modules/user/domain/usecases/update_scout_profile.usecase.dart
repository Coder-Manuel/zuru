import 'dart:async';

import 'package:zuru/core/entities/profile.entity.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/user/data/models/scout_profile_edit.input.dart';
import 'package:zuru/modules/user/domain/repository/user_repository.dart';

/// Persists the editable fields of the scout's World Profile.
class UpdateScoutProfileUseCase
    implements UseCase<Profile, ScoutProfileEditInput> {
  final UserRepository repo;
  UpdateScoutProfileUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<Profile>> call(ScoutProfileEditInput params) =>
      repo.updateScoutProfile(params);
}
