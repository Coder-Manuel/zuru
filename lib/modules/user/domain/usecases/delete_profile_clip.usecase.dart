import 'dart:async';

import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/user/domain/repository/user_repository.dart';

/// Removes a clip row by its id.
class DeleteProfileClipUseCase implements UseCase<void, String> {
  final UserRepository repo;
  DeleteProfileClipUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<void>> call(String id) => repo.deleteProfileClip(id);
}
