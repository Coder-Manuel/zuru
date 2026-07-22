import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/utils/error_wrapper.dart';
import 'package:zuru/modules/rating/data/models/rating.input.dart';
import 'package:zuru/modules/rating/data/models/rating.model.dart';
import 'package:zuru/modules/rating/data/sources/remote_rating_datasource.dart';
import 'package:zuru/modules/rating/domain/entities/rating.entity.dart';
import 'package:zuru/modules/rating/domain/repository/rating_repository.dart';

class RatingRepositoryImpl implements RatingRepository {
  final _library = 'Rating Repository';
  final RemoteRatingDatasource remoteDatasource;

  RatingRepositoryImpl({required this.remoteDatasource});

  @override
  Future<RepoResponse<RatingEntity>> createRating(
    CreateRatingInput input,
  ) async {
    final response = await ErrorWrapper.async<RepoResponse<RatingEntity>>(
      () async {
        final data = await remoteDatasource.createRating(input.toMap());
        return SuccessResponse(RatingModel.fromMap(data));
      },
      onError: (_) => FailureResponse('Failed to rating guide, kindly retry'),
      library: _library,
      description: 'while creating a rating',
    );
    return response!;
  }
}
