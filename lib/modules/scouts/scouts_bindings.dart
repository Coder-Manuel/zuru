import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/modules/scouts/data/repositories_impl/scouts_repository_impl.dart';
import 'package:zuru/modules/scouts/data/sources/remote_scouts_datasource.dart';
import 'package:zuru/modules/scouts/domain/repository/scouts_repository.dart';
import 'package:zuru/modules/scouts/domain/usecases/get_scout_detail.usecase.dart';
import 'package:zuru/modules/scouts/domain/usecases/get_scouts_feed.usecase.dart';
import 'package:zuru/modules/scouts/presentation/controllers/scouts_feed_controller.dart';

class ScoutsBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RemoteScoutsDatasource>(
      () => RemoteScoutsDatasourceImpl(client: Get.find<SupabaseClient>()),
      fenix: true,
    );
    Get.lazyPut<ScoutsRepository>(
      () => ScoutsRepositoryImpl(
        remoteDatasource: Get.find<RemoteScoutsDatasource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<GetScoutsFeedUseCase>(
      () => GetScoutsFeedUseCase(repo: Get.find<ScoutsRepository>()),
      fenix: true,
    );
    Get.lazyPut<GetScoutDetailUseCase>(
      () => GetScoutDetailUseCase(repo: Get.find<ScoutsRepository>()),
      fenix: true,
    );

    // Feed controller backs the client "Scouts" tab (always alive).
    Get.lazyPut<ScoutsFeedController>(
      () => ScoutsFeedController(
        getScoutsFeed: Get.find<GetScoutsFeedUseCase>(),
      ),
      fenix: true,
    );

    // NOTE: ScoutDetailController is bound per-navigation via the detail route
    // (see scouts_routes.dart) so it re-fetches on each visit.
  }
}
