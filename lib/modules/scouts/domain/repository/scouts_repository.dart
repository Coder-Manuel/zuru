import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';

abstract class ScoutsRepository {
  /// Returns scouts as [User]s (each carrying their scout [Profile]).
  Future<RepoResponse<List<User>>> getScoutsFeed({
    required int from,
    required int to,
    bool availableOnly = false,
    String? tag,
  });

  Future<RepoResponse<User>> getScoutDetail(String profileId);
}
