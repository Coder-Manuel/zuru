import 'dart:async';

import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/auth/data/models/auth.inputs.dart';
import 'package:zuru/modules/auth/domain/repository/auth_repository.dart';

/// Alias for [SignupInput] — registers/signs-up a new user with email + password.
class RegisterUsecase implements UseCase<User, SignupInput> {
  final AuthRepository repo;
  RegisterUsecase({required this.repo});

  @override
  FutureOr<RepoResponse<User>> call(SignupInput params) => repo.signup(params);
}
