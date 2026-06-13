import 'dart:async';

import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/scouts/domain/repository/scouts_repository.dart';

class GetScoutDetailUseCase implements UseCase<User, String> {
  final ScoutsRepository repo;
  GetScoutDetailUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<User>> call(String profileId) =>
      repo.getScoutDetail(profileId);
}
