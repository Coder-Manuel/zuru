import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';

/// Returns a live [Stream] of the current user's [accepted] and [live] missions.
///
/// This is a streaming use case — it does not implement the standard
/// [UseCase<T, Params>] interface because it emits multiple values over time
/// rather than a single [RepoResponse]. The stream itself never errors;
/// failures are swallowed by the Supabase client and surface as empty lists.
class WatchActiveMissionsUseCase
    extends StreamUseCase<List<MissionEntity>, dynamic> {
  final MissionsRepository repo;
  WatchActiveMissionsUseCase({required this.repo});

  @override
  Stream<RepoResponse<List<MissionEntity>>> call([_]) =>
      repo.watchActiveMissions();
}
