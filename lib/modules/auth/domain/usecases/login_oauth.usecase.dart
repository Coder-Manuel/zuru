import 'dart:async';

import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/auth/data/models/auth.inputs.dart';
import 'package:zuru/modules/auth/domain/repository/auth_repository.dart';

class LoginOAuthUseCase implements UseCase<User, OAuthInput> {
  final AuthRepository repo;
  LoginOAuthUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<User>> call(OAuthInput params) =>
      repo.loginWithOAuth(params);
}
