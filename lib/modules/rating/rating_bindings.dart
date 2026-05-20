import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/modules/rating/data/repositories_impl/rating_repository_impl.dart';
import 'package:zuru/modules/rating/data/sources/remote_rating_datasource.dart';
import 'package:zuru/modules/rating/domain/repository/rating_repository.dart';
import 'package:zuru/modules/rating/domain/usecases/create_rating.usecase.dart';
import 'package:zuru/modules/rating/presentation/controllers/rating.controller.dart';

class RatingBindings extends Bindings {
  @override
  void dependencies() {
    // ── Data layer ────────────────────────────────────────────────────────────
    Get.lazyPut<RemoteRatingDatasource>(
      () => RemoteRatingDatasourceImpl(client: Get.find<SupabaseClient>()),
      fenix: true,
    );
    Get.lazyPut<RatingRepository>(
      () => RatingRepositoryImpl(
        remoteDatasource: Get.find<RemoteRatingDatasource>(),
      ),
      fenix: true,
    );

    // ── Use cases ─────────────────────────────────────────────────────────────
    Get.lazyPut<CreateRatingUseCase>(
      () => CreateRatingUseCase(repo: Get.find<RatingRepository>()),
      fenix: true,
    );

    // ── Controllers ───────────────────────────────────────────────────────────
    Get.lazyPut<RatingController>(
      () => RatingController(
        createRatingUsecase: Get.find<CreateRatingUseCase>(),
      ),
      fenix: true,
    );
  }
}
