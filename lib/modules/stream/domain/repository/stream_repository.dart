import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/stream/data/models/stream.inputs.dart';
import 'package:zuru/modules/stream/domain/entities/livekit_session.entity.dart';

abstract class StreamRepository {
  /// Invokes the `join-stream` edge function — client viewer credentials.
  Future<RepoResponse<LiveKitSessionEntity>> joinStream(String missionId);

  /// Invokes the `go-live` edge function — scout publisher credentials.
  Future<RepoResponse<LiveKitSessionEntity>> goLive(InitStreamInput input);
}
