import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/stream/domain/entities/livekit_session.entity.dart';

abstract class StreamRepository {
  /// Invokes the `join-stream` edge function and returns the LiveKit viewer
  /// credentials for [missionId].
  Future<RepoResponse<LiveKitSessionEntity>> joinStream(String missionId);
}
