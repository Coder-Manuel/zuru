import 'dart:async';

import 'package:zuru/core/entities/profile_clip.entity.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/user/domain/repository/user_repository.dart';

/// Fetches all clip rows for a given profile id.
class GetProfileClipsUseCase implements UseCase<List<ProfileClip>, String> {
  final UserRepository repo;
  GetProfileClipsUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<List<ProfileClip>>> call(String profileId) =>
      repo.getProfileClips(profileId);
}
