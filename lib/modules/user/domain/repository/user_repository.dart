import 'dart:io';

import 'package:zuru/core/entities/profile.entity.dart';
import 'package:zuru/core/entities/profile_clip.entity.dart';
import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/user/data/models/scout_profile_edit.input.dart';

abstract class UserRepository {
  Future<RepoResponse<User>> getUserInfo();
  Future<RepoResponse<void>> updateFcmToken(String token);

  /// Persists [role] as the user's `default_role` in the `users` table.
  Future<RepoResponse<void>> updateDefaultRole(UserRole role);

  // ── Scout World Profile ─────────────────────────────────────────────────
  /// Persists the editable scout profile fields, returning the updated profile.
  Future<RepoResponse<Profile>> updateScoutProfile(ScoutProfileEditInput input);

  /// Uploads [file] to storage and returns its public URL.
  Future<RepoResponse<String>> uploadMedia(File file, {required String folder});

  Future<RepoResponse<List<ProfileClip>>> getProfileClips(String profileId);

  Future<RepoResponse<ProfileClip>> upsertProfileClip({
    required String profileId,
    required ClipType type,
    required String mediaUrl,
    String? title,
  });

  Future<RepoResponse<void>> deleteProfileClip(String id);
}
