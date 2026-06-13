import 'dart:async';

import 'package:zuru/core/entities/profile_clip.entity.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/user/domain/repository/user_repository.dart';

class AddClipParams {
  final String profileId;
  final String mediaUrl;
  final String? title;
  const AddClipParams({
    required this.profileId,
    required this.mediaUrl,
    this.title,
  });
}

/// Adds a single clip to a scout profile (max enforced by the UI/controller).
class AddProfileClipUseCase implements UseCase<ProfileClip, AddClipParams> {
  final UserRepository repo;
  AddProfileClipUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<ProfileClip>> call(AddClipParams params) =>
      repo.addProfileClip(
        profileId: params.profileId,
        mediaUrl: params.mediaUrl,
        title: params.title,
      );
}
