import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/models/user.model.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/utils/error_wrapper.dart';
import 'package:zuru/modules/scouts/data/sources/remote_scouts_datasource.dart';
import 'package:zuru/modules/scouts/domain/repository/scouts_repository.dart';

class ScoutsRepositoryImpl extends ScoutsRepository {
  final _library = 'Scouts Repository';
  final RemoteScoutsDatasource remoteDatasource;

  ScoutsRepositoryImpl({required this.remoteDatasource});

  @override
  Future<RepoResponse<List<User>>> getScoutsFeed({
    required int from,
    required int to,
    bool availableOnly = false,
    String? tag,
  }) async {
    final response = await ErrorWrapper.async<RepoResponse<List<User>>>(
      () async {
        final rows = await remoteDatasource.getScoutsFeed(
          from: from,
          to: to,
          availableOnly: availableOnly,
          tag: tag,
        );
        return SuccessResponse(rows.map(_rowToUser).toList());
      },
      onError: (_) => FailureResponse('Could not load scouts, kindly retry'),
      library: _library,
      description: 'while loading scouts feed',
    );
    return response!;
  }

  @override
  Future<RepoResponse<User>> getScoutDetail(String profileId) async {
    final response = await ErrorWrapper.async<RepoResponse<User>>(
      () async {
        final data = await remoteDatasource.getScoutDetail(profileId);
        if (data == null || data.isEmpty) {
          return FailureResponse('Scout not found');
        }
        return SuccessResponse(_rowToUser(data));
      },
      onError: (_) => FailureResponse('Could not load scout, kindly retry'),
      library: _library,
      description: 'while loading scout detail',
    );
    return response!;
  }

  /// Reshapes a `profiles` row (with embedded parent `users`) into the shape
  /// [UserModel.fromMap] expects: the user object with a single-element
  /// `profiles` list holding this scout profile.
  User _rowToUser(Map<String, dynamic> row) {
    final userMap = Map<String, dynamic>.from(
      (row['users'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final profileMap = Map<String, dynamic>.from(row)..remove('users');
    userMap['profiles'] = [profileMap];
    return UserModel.fromMap(userMap);
  }
}
