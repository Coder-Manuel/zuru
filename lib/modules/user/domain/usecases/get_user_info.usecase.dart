import 'dart:async';

import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/user/domain/repository/user_repository.dart';

class GetUserInfoUseCase implements UseCase<User, dynamic> {
  final UserRepository repo;
  GetUserInfoUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<User>> call([params]) {
    return repo.getUserInfo();
  }
}
