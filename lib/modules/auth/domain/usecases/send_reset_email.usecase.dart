import 'dart:async';

import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/auth/data/models/auth.inputs.dart';
import 'package:zuru/modules/auth/domain/repository/auth_repository.dart';

class SendResetEmailUseCase implements UseCase<bool, ForgotPasswordInput> {
  final AuthRepository repo;
  SendResetEmailUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<bool>> call(ForgotPasswordInput params) =>
      repo.sendPasswordResetEmail(params);
}
