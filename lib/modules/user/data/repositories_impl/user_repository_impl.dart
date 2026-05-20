import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/models/user.model.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/utils/error_wrapper.dart';
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
}
