import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/entities/session.entity.dart';
import 'package:zuru/modules/missions/domain/usecases/get_my_missions.usecase.dart';
import 'package:zuru/core/routes/app_routes.dart';

enum MissionFilter { all, active, pending, completed }

class MissionsTabController extends GetxController {
  final _getMyMissionsUseCase = Get.find<GetMyMissionsUseCase>();

  // ── State ─────────────────────────────────────────────────────────────────
  final RxList<MissionEntity> _missions = <MissionEntity>[].obs;
  final Rx<MissionFilter> activeFilter = MissionFilter.all.obs;
  final RxBool isLoading = true.obs;
  final RxMap<String, SessionEntity> activeSessions =
      <String, SessionEntity>{}.obs;

  RealtimeChannel? _sessionChannel;

  // ── Derived ───────────────────────────────────────────────────────────────

  List<MissionEntity> get filteredMissions {
    final filter = activeFilter.value;
    return switch (filter) {
      MissionFilter.all => _missions.toList(),
      MissionFilter.active =>
        _missions
            .where(
              (m) =>
                  m.status == MissionStatus.accepted ||
                  m.status == MissionStatus.enroute ||
                  m.status == MissionStatus.live,
            )
            .toList(),
      MissionFilter.pending =>
        _missions.where((m) => m.status == MissionStatus.open).toList(),
      MissionFilter.completed =>
        _missions.where((m) => m.status == MissionStatus.completed).toList(),
    };
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onReady() {
    super.onReady();
    fetchMissions();
  }

  @override
  void onClose() {
    _sessionChannel?.unsubscribe();
    super.onClose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void setFilter(MissionFilter filter) => activeFilter.value = filter;

  Future<void> fetchMissions() async {
    isLoading.value = true;
    final response = await _getMyMissionsUseCase(null);
    isLoading.value = false;

    response.fold((err) => Toast.error(err.message), (data) {
      _missions.assignAll(data);
    });
  }

  /// Navigate to the stream session.
  /// [StreamRoleMiddleware] on [AppRoutes.stream] renders [StreamPage] for
  /// scouts and [JoinStreamPage] for clients.
  void onJoinStream(MissionEntity mission) {
    Get.toNamed(AppRoutes.stream, arguments: mission);
  }
}
