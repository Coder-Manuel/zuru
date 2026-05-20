import 'dart:async';

import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/auth/domain/repository/auth_repository.dart';

class LogoutUseCase implements UseCase<bool, dynamic> {
  final AuthRepository repo;
  LogoutUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<bool>> call([_]) => repo.logout();
}
