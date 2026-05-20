import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/rating/data/models/rating.input.dart';
import 'package:zuru/modules/rating/domain/entities/rating.entity.dart';
import 'package:zuru/modules/rating/domain/repository/rating_repository.dart';

class CreateRatingUseCase extends UseCase<RatingEntity, CreateRatingInput> {
  final RatingRepository repo;

  CreateRatingUseCase({required this.repo});

  @override
  Future<RepoResponse<RatingEntity>> call(CreateRatingInput input) =>
      repo.createRating(input);
}
