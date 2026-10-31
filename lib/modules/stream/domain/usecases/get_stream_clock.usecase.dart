import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/stream/domain/entities/stream_clock.entity.dart';
import 'package:zuru/modules/stream/domain/repository/stream_repository.dart';

class GetStreamClockUseCase extends UseCase<StreamClockEntity, String> {
  final StreamRepository repo;

  GetStreamClockUseCase({required this.repo});

  @override
  Future<RepoResponse<StreamClockEntity>> call(String missionId) =>
      repo.getStreamClock(missionId);
}
