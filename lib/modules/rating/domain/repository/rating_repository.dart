import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/rating/data/models/rating.input.dart';
import 'package:zuru/modules/rating/domain/entities/rating.entity.dart';

abstract class RatingRepository {
  Future<RepoResponse<RatingEntity>> createRating(CreateRatingInput input);
}
