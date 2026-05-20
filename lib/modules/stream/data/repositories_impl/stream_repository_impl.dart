import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/utils/error_wrapper.dart';
import 'package:zuru/modules/stream/data/models/livekit_session.model.dart';
import 'package:zuru/modules/stream/data/sources/remote_stream_datasource.dart';
import 'package:zuru/modules/stream/domain/entities/livekit_session.entity.dart';
import 'package:zuru/modules/stream/domain/repository/stream_repository.dart';

class StreamRepositoryImpl implements StreamRepository {
  final _library = 'Stream Repository';
  final RemoteStreamDatasource remoteDatasource;

  StreamRepositoryImpl({required this.remoteDatasource});

  @override
  Future<RepoResponse<LiveKitSessionEntity>> joinStream(
    String missionId,
  ) async {
    final response =
        await ErrorWrapper.async<RepoResponse<LiveKitSessionEntity>>(
          () async {
            final res = await remoteDatasource.joinStream(missionId: missionId);

            if (res.status != 200) {
              return FailureResponse(
                'Failed to join stream (HTTP ${res.status}).',
              );
            }

            return SuccessResponse(LiveKitSessionModel.fromMap(res.data));
          },
          onError: (_) => FailureResponse('Failed to join stream.'),
          library: _library,
          description: 'while joining stream',
        );

    return response!;
  }
}
