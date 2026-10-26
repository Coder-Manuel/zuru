import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/modules/stream/data/repositories_impl/stream_repository_impl.dart';
import 'package:zuru/modules/stream/data/sources/remote_stream_datasource.dart';
import 'package:zuru/modules/stream/domain/repository/stream_repository.dart';
import 'package:zuru/modules/stream/domain/usecases/go_live.usecase.dart';
import 'package:zuru/modules/stream/domain/usecases/join_stream.usecase.dart';

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
    Get.lazyPut<GoLiveUseCase>(
      () => GoLiveUseCase(repo: Get.find<StreamRepository>()),
      fenix: true,
    );

    // Controllers are created per page (StreamPage / JoinStreamPage), each
    // owning its own LiveKit room.
  }
}
