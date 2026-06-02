import 'dart:async';

import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/auth/data/models/auth.inputs.dart';
import 'package:zuru/modules/auth/domain/repository/auth_repository.dart';

class VerifyResetOtpUseCase implements UseCase<bool, VerifyOtpInput> {
  final AuthRepository repo;
  VerifyResetOtpUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<bool>> call(VerifyOtpInput params) =>
      repo.verifyPasswordResetOtp(params);
}
