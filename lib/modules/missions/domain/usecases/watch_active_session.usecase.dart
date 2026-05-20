import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/missions/domain/entities/session.entity.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';

class WatchActiveSessionUseCase
    extends StreamUseCase<SessionEntity, List<String>> {
  final MissionsRepository repo;

  WatchActiveSessionUseCase({required this.repo});

  @override
  Stream<RepoResponse<SessionEntity>> call(List<String> input) =>
      repo.watchLiveSession(input);
}
