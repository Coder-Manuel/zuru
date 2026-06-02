import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/core/remote/network_client.dart';
import 'package:zuru/modules/missions/data/repositories_impl/missions_repository_impl.dart';
import 'package:zuru/modules/missions/data/sources/remote_missions_datasource.dart';
import 'package:zuru/modules/missions/data/sources/remote_places_datasource.dart';
import 'package:zuru/modules/missions/domain/repository/missions_repository.dart';
import 'package:zuru/modules/missions/domain/usecases/accept_mission.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/get_my_missions.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/get_nearby_scouts.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/nearby_missions.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/post_mission.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/update_mission_status.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/watch_active_mission.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/watch_active_missions.usecase.dart';
import 'package:zuru/modules/missions/domain/usecases/watch_active_session.usecase.dart';
import 'package:zuru/modules/missions/presentation/controllers/finding_scouts_controller.dart';
import 'package:zuru/modules/missions/presentation/controllers/location_picker_controller.dart';
import 'package:zuru/modules/missions/presentation/controllers/missions_controller.dart';
import 'package:zuru/modules/missions/presentation/controllers/missions_tab_controller.dart';
import 'package:zuru/modules/missions/presentation/controllers/post_mission_controller.dart';
import 'package:zuru/modules/missions/presentation/controllers/radar_controller.dart';

class MissionsBindings extends Bindings {
  @override
  void dependencies() {
    // ── Data layer ────────────────────────────────────────────────────────────
    Get.lazyPut<RemoteMissionsDatasource>(
      () => RemoteMissionsDatasourceImpl(client: Get.find<SupabaseClient>()),
      fenix: true,
    );

    // Dedicated Dio instance for Google Places / Geocoding APIs
    Get.lazyPut<RemotePlacesDatasource>(
      () => RemotePlacesDatasourceImpl(
        dio: Get.find<Dio>(tag: NetworkDioClientType.global.name),
      ),
      fenix: true,
    );

    Get.lazyPut<MissionsRepository>(
      () => MissionsRepositoryImpl(
        remoteDatasource: Get.find<RemoteMissionsDatasource>(),
      ),
      fenix: true,
    );

    // ── Use cases: client ─────────────────────────────────────────────────────
    Get.lazyPut<PostMissionUseCase>(
      () => PostMissionUseCase(repo: Get.find<MissionsRepository>()),
      fenix: true,
    );
    Get.lazyPut<GetNearbyScoutsUseCase>(
      () => GetNearbyScoutsUseCase(repo: Get.find<MissionsRepository>()),
      fenix: true,
    );
    Get.lazyPut<WatchActiveMissionsUseCase>(
      () => WatchActiveMissionsUseCase(repo: Get.find<MissionsRepository>()),
      fenix: true,
    );
    Get.lazyPut<WatchActiveSessionUseCase>(
      () => WatchActiveSessionUseCase(repo: Get.find<MissionsRepository>()),
      fenix: true,
    );

    // ── Use cases: scout ──────────────────────────────────────────────────────
    Get.lazyPut<GetMyMissionsUseCase>(
      () => GetMyMissionsUseCase(repo: Get.find<MissionsRepository>()),
      fenix: true,
    );
    Get.lazyPut<NearbyMissionsUseCase>(
      () => NearbyMissionsUseCase(repo: Get.find<MissionsRepository>()),
      fenix: true,
    );
    Get.lazyPut<WatchActiveMissionUseCase>(
      () => WatchActiveMissionUseCase(repo: Get.find<MissionsRepository>()),
      fenix: true,
    );
    Get.lazyPut<AcceptMissionUseCase>(
      () => AcceptMissionUseCase(repo: Get.find<MissionsRepository>()),
      fenix: true,
    );
    Get.lazyPut<UpdateMissionStatusUseCase>(
      () => UpdateMissionStatusUseCase(repo: Get.find<MissionsRepository>()),
      fenix: true,
    );

    // ── Controllers: client ───────────────────────────────────────────────────
    Get.lazyPut<MissionsTabController>(
      () => MissionsTabController(),
      fenix: true,
    );
    Get.lazyPut<PostMissionController>(
      () => PostMissionController(),
      fenix: true,
    );
    Get.lazyPut<FindingScoutsController>(
      () => FindingScoutsController(),
      fenix: true,
    );
    Get.lazyPut<LocationPickerController>(
      () => LocationPickerController(),
      fenix: true,
    );

    // ── Controllers: scout ────────────────────────────────────────────────────
    Get.lazyPut<RadarController>(() => RadarController(), fenix: true);
    Get.lazyPut<MissionsController>(() => MissionsController(), fenix: true);
  }
}
