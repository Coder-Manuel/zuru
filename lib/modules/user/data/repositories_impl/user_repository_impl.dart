import 'dart:io';

import 'package:zuru/core/entities/profile.entity.dart';
import 'package:zuru/core/entities/profile_clip.entity.dart';
import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/models/profile.model.dart';
import 'package:zuru/core/models/profile_clip.model.dart';
import 'package:zuru/core/models/user.model.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/utils/error_wrapper.dart';
import 'package:zuru/modules/user/data/models/scout_profile_edit.input.dart';
import 'package:zuru/modules/user/data/sources/remote_user_datasource.dart';
import 'package:zuru/modules/user/domain/repository/user_repository.dart';

class UserRepositoryImpl extends UserRepository {
  final _library = 'User Repository';
  final RemoteUserDatasource remoteDatasource;

  UserRepositoryImpl({required this.remoteDatasource});

  @override
  Future<RepoResponse<User>> getUserInfo() async {
    final response = await ErrorWrapper.async<RepoResponse<User>>(
      () async {
        final data = await remoteDatasource.getUseInfo();

        if (data == null || data.isEmpty) {
          return FailureResponse('No User Data');
        }

        final user = UserModel.fromMap(data);

        return SuccessResponse(user);
      },
      onError: (error) {
        return FailureResponse('An error occurred, Kindly Retry');
      },
      library: _library,
      description: 'while fetching user data',
    );

    return response!;
  }

  @override
  Future<RepoResponse<void>> updateFcmToken(String token) async {
    final response = await ErrorWrapper.async<RepoResponse<void>>(
      () async {
        await remoteDatasource.updateFcmToken(token);
        return SuccessResponse(null);
      },
      onError: (_) => FailureResponse('Failed to update notification token'),
      library: _library,
      description: 'while updating FCM token',
    );
    return response!;
  }

  @override
  Future<RepoResponse<void>> updateDefaultRole(UserRole role) async {
    final response = await ErrorWrapper.async<RepoResponse<void>>(
      () async {
        await remoteDatasource.updateDefaultRole(role.name);
        return SuccessResponse(null);
      },
      onError: (_) =>
          FailureResponse('Could not switch role, please try again'),
      library: _library,
      description: 'while updating default role',
    );
    return response!;
  }

  @override
  Future<RepoResponse<Profile>> updateScoutProfile(
    ScoutProfileEditInput input,
  ) async {
    final response = await ErrorWrapper.async<RepoResponse<Profile>>(
      () async {
        final data = await remoteDatasource.updateScoutProfile(input.toMap());
        if (data == null || data.isEmpty) {
          return FailureResponse('Could not save profile');
        }
        return SuccessResponse(ProfileModel.fromMap(data));
      },
      onError: (_) => FailureResponse('Could not save profile, please retry'),
      library: _library,
      description: 'while updating scout profile',
    );
    return response!;
  }

  @override
  Future<RepoResponse<String>> uploadMedia(
    File file, {
    required String folder,
  }) async {
    final response = await ErrorWrapper.async<RepoResponse<String>>(
      () async {
        final url = await remoteDatasource.uploadMedia(file, folder: folder);
        return SuccessResponse(url);
      },
      onError: (_) => FailureResponse('Upload failed, please try again'),
      library: _library,
      description: 'while uploading media',
    );
    return response!;
  }

  @override
  Future<RepoResponse<List<ProfileClip>>> getProfileClips(
    String profileId,
  ) async {
    final response = await ErrorWrapper.async<RepoResponse<List<ProfileClip>>>(
      () async {
        final rows = await remoteDatasource.getProfileClips(profileId);
        final clips = rows.map<ProfileClip>(ProfileClipModel.fromMap).toList();
        return SuccessResponse(clips);
      },
      onError: (_) => FailureResponse('Could not load clips'),
      library: _library,
      description: 'while fetching profile clips',
    );
    return response!;
  }

  @override
  Future<RepoResponse<ProfileClip>> addProfileClip({
    required String profileId,
    required String mediaUrl,
    String? title,
  }) async {
    final response = await ErrorWrapper.async<RepoResponse<ProfileClip>>(
      () async {
        final payload = ProfileClipModel(
          profileId: profileId,
          mediaUrl: mediaUrl,
          title: title,
        ).toInsertMap();

        final data = await remoteDatasource.addProfileClip(payload);
        return SuccessResponse(ProfileClipModel.fromMap(data));
      },
      onError: (_) => FailureResponse('Could not save clip, please retry'),
      library: _library,
      description: 'while adding profile clip',
    );
    return response!;
  }

  @override
  Future<RepoResponse<void>> deleteProfileClip(String id) async {
    final response = await ErrorWrapper.async<RepoResponse<void>>(
      () async {
        await remoteDatasource.deleteProfileClip(id);
        return SuccessResponse(null);
      },
      onError: (_) => FailureResponse('Could not remove clip'),
      library: _library,
      description: 'while deleting profile clip',
    );
    return response!;
  }
}
