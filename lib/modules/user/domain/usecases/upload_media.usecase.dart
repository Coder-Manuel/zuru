import 'dart:async';
import 'dart:io';

import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/user/domain/repository/user_repository.dart';

class UploadMediaParams {
  final File file;
  final String folder;
  const UploadMediaParams({required this.file, required this.folder});
}

/// Uploads a file to storage and returns its public URL.
class UploadMediaUseCase implements UseCase<String, UploadMediaParams> {
  final UserRepository repo;
  UploadMediaUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<String>> call(UploadMediaParams params) =>
      repo.uploadMedia(params.file, folder: params.folder);
}
