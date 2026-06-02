import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';

abstract class UserRepository {
  Future<RepoResponse<User>> getUserInfo();
  Future<RepoResponse<void>> updateFcmToken(String token);

  /// Persists [role] as the user's `default_role` in the `users` table.
  Future<RepoResponse<void>> updateDefaultRole(UserRole role);
}
