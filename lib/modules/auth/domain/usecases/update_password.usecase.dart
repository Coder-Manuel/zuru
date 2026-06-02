import 'dart:async';

import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/auth/data/models/auth.inputs.dart';
import 'package:zuru/modules/auth/domain/repository/auth_repository.dart';

class UpdatePasswordUseCase implements UseCase<bool, UpdatePasswordInput> {
  final AuthRepository repo;
  UpdatePasswordUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<bool>> call(UpdatePasswordInput params) =>
      repo.updatePassword(params);
}
