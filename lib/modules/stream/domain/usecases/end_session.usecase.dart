import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/stream/domain/repository/stream_repository.dart';

class EndSessionUseCase extends UseCase<bool, String> {
  final StreamRepository repo;

  EndSessionUseCase({required this.repo});

  @override
  Future<RepoResponse<bool>> call(String missionId) =>
      repo.endSession(missionId);
}
