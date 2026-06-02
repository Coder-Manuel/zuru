import 'dart:async';

import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/auth/data/models/auth.inputs.dart';
import 'package:zuru/modules/auth/domain/repository/auth_repository.dart';

class LoginUseCase implements UseCase<User, LoginInput> {
  final AuthRepository repo;
  LoginUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<User>> call(LoginInput params) => repo.login(params);
}
