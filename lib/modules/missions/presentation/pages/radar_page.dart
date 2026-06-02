import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/modules/missions/presentation/controllers/radar_controller.dart';
import 'package:zuru/modules/missions/presentation/widgets/active_mission_panel.dart';
import 'package:zuru/modules/missions/presentation/widgets/available_missions_panel.dart';
import 'package:zuru/modules/missions/presentation/widgets/radar_map.dart';

class RadarPage extends GetView<RadarController> {
  const RadarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (_, constraints) {
          return Column(
            children: [
              // ── Radar map ─────────────────────────────────────────────
              Obx(() {
                final mapHeight =
                    constraints.maxHeight *
                    (controller.hasActiveMission ? 0.35 : 0.65);

                return SizedBox(
                  height: mapHeight,
                  child: RadarMap(mapHeight: mapHeight),
                );
              }),

              // ── Bottom panel — switches on active mission state ────────
              Expanded(
                child: Obx(
                  () => controller.hasActiveMission
                      ? const ActiveMissionPanel()
                      : const MissionsPanel(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
