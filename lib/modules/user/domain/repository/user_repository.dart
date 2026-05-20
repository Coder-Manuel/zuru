import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';

abstract class UserRepository {
  Future<RepoResponse<User>> getUserInfo();
  Future<RepoResponse<void>> updateFcmToken(String token);
}
