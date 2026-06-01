import 'dart:async';

import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/user/domain/repository/user_repository.dart';

class UpdateDefaultRoleUseCase implements UseCase<void, UserRole> {
  final UserRepository repo;
  UpdateDefaultRoleUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<void>> call(UserRole params) =>
      repo.updateDefaultRole(params);
}
