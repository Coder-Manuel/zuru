import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/missions/domain/entities/mission_page.entity.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';

/// Live [Stream] of changes to the live-check pool — missions added, updated
/// or removed — so the radar can patch its lists instead of re-querying.
class WatchMissionPoolUseCase extends StreamUseCase<MissionPoolEvent, dynamic> {
  final MissionsRepository repo;
  WatchMissionPoolUseCase({required this.repo});

  @override
  Stream<RepoResponse<MissionPoolEvent>> call([_]) => repo.watchMissionPool();
}
