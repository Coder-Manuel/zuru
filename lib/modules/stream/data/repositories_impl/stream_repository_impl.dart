import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/utils/error_wrapper.dart';
import 'package:zuru/modules/stream/data/models/livekit_session.model.dart';
import 'package:zuru/modules/stream/data/models/stream.inputs.dart';
import 'package:zuru/modules/stream/data/models/stream_clock.model.dart';
import 'package:zuru/modules/stream/data/sources/remote_stream_datasource.dart';
import 'package:zuru/modules/stream/domain/entities/livekit_session.entity.dart';
import 'package:zuru/modules/stream/domain/entities/stream_clock.entity.dart';
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
            final res = await remoteDatasource.goLive(missionId: missionId);
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

  @override
  Future<RepoResponse<LiveKitSessionEntity>> goLive(
    InitStreamInput input,
  ) async {
    final response =
        await ErrorWrapper.async<RepoResponse<LiveKitSessionEntity>>(
          () async {
            final res = await remoteDatasource.goLive(
              missionId: input.missionId,
            );
            if (res.status != 200) {
              return FailureResponse(
                'Failed to start stream (HTTP ${res.status}).',
              );
            }
            return SuccessResponse(LiveKitSessionModel.fromMap(res.data));
          },
          onError: (_) => FailureResponse('Failed to start stream.'),
          library: _library,
          description: 'while going live',
        );
    return response!;
  }

  @override
  Future<RepoResponse<StreamClockEntity>> getStreamClock(
    String missionId,
  ) async {
    final response = await ErrorWrapper.async<RepoResponse<StreamClockEntity>>(
      () async {
        final row = await remoteDatasource.streamClock(missionId: missionId);
        if (row == null) return FailureResponse('No stream session yet.');
        return SuccessResponse(
          StreamClockModel.fromMap(row, receivedAt: DateTime.now()),
        );
      },
      onError: (_) => FailureResponse('Failed to read the stream clock.'),
      library: _library,
      description: 'while reading the stream clock',
    );
    return response!;
  }

  @override
  Future<RepoResponse<bool>> endSession(String missionId) async {
    final response = await ErrorWrapper.async<RepoResponse<bool>>(
      () async {
        final res = await remoteDatasource.endSession(missionId: missionId);
        if (res.status != 200) {
          return FailureResponse(
            'Failed to end the live check (HTTP ${res.status}).',
          );
        }
        return SuccessResponse(true);
      },
      onError: (_) => FailureResponse('Failed to end the live check.'),
      library: _library,
      description: 'while ending the session',
    );
    return response!;
  }
}
