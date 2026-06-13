import 'dart:async';

import 'package:zuru/core/entities/profile_clip.entity.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/user/domain/repository/user_repository.dart';

class UpsertClipParams {
  final String profileId;
  final ClipType type;
  final String mediaUrl;
  final String? title;
  const UpsertClipParams({
    required this.profileId,
    required this.type,
    required this.mediaUrl,
    this.title,
  });
}

/// Inserts or updates a single clip slot for a scout profile.
class UpsertProfileClipUseCase implements UseCase<ProfileClip, UpsertClipParams> {
  final UserRepository repo;
  UpsertProfileClipUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<ProfileClip>> call(UpsertClipParams params) =>
      repo.upsertProfileClip(
        profileId: params.profileId,
        type: params.type,
        mediaUrl: params.mediaUrl,
        title: params.title,
      );
}
