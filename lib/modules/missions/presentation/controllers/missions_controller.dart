import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/usecases/get_my_missions.usecase.dart';
import 'package:zuru/modules/missions/presentation/pages/mission_details_page.dart';

enum MissionFilter { all, active, accepted, completed }

class MissionsController extends GetxController {
  final _getMyMissionsUseCase = Get.find<GetMyMissionsUseCase>();

  // ── State ─────────────────────────────────────────────────────────────────
  final RxList<MissionEntity> _missions = <MissionEntity>[].obs;
  final Rx<MissionFilter> activeFilter = MissionFilter.all.obs;
  final RxBool isLoading = true.obs;

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
                  m.status == MissionStatus.enroute ||
                  m.status == MissionStatus.live,
            )
            .toList(),
      MissionFilter.accepted =>
        _missions.where((m) => m.status == MissionStatus.accepted).toList(),
      MissionFilter.completed =>
        _missions.where((m) => m.status == MissionStatus.completed).toList(),
    };
  }

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

  void onTapMission(MissionEntity mission) {
    Get.toNamed(MissionDetailsPage.route, arguments: mission);
  }
}
