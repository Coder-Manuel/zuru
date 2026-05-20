import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/modules/stream/data/repositories_impl/stream_repository_impl.dart';
import 'package:zuru/modules/stream/data/sources/remote_stream_datasource.dart';
import 'package:zuru/modules/stream/domain/repository/stream_repository.dart';
import 'package:zuru/modules/stream/domain/usecases/join_stream.usecase.dart';
import 'package:zuru/modules/stream/presentation/controllers/join_stream_controller.dart';

class StreamBindings extends Bindings {
  @override
  void dependencies() {
    // ── Data layer ────────────────────────────────────────────────────────────
    Get.lazyPut<RemoteStreamDatasource>(
      () => RemoteStreamDatasourceImpl(client: Get.find<SupabaseClient>()),
      fenix: true,
    );
    Get.lazyPut<StreamRepository>(
      () => StreamRepositoryImpl(
        remoteDatasource: Get.find<RemoteStreamDatasource>(),
      ),
      fenix: true,
    );

    // ── Use cases ─────────────────────────────────────────────────────────────
    Get.lazyPut<JoinStreamUseCase>(
      () => JoinStreamUseCase(repo: Get.find<StreamRepository>()),
      fenix: true,
    );

    // ── Controllers ───────────────────────────────────────────────────────────
    Get.lazyPut<JoinStreamController>(
      () => JoinStreamController(
        joinStreamUseCase: Get.find<JoinStreamUseCase>(),
      ),
      fenix: true,
    );
  }
}
