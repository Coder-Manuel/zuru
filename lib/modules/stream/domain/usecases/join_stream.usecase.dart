import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/stream/domain/entities/livekit_session.entity.dart';
import 'package:zuru/modules/stream/domain/repository/stream_repository.dart';

class JoinStreamUseCase extends UseCase<LiveKitSessionEntity, String> {
  final StreamRepository repo;

  JoinStreamUseCase({required this.repo});

  @override
  Future<RepoResponse<LiveKitSessionEntity>> call(String missionId) =>
      repo.joinStream(missionId);
}
