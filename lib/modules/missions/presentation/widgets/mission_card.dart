import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/utils/extensions.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/core/widgets/location_listener.builder.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/presentation/pages/mission_details_page.dart';

/// A single available-mission row. Shared by the radar [MissionsPanel] preview
/// list and the "all missions" bottom sheet.
///
/// Tapping opens the mission details page. Pass [onTap] to override (e.g. to
/// close a sheet before navigating).
class MissionCard extends StatelessWidget {
  final MissionEntity mission;
  final VoidCallback? onTap;

  const MissionCard({super.key, required this.mission, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          onTap ??
          () => Get.toNamed(MissionDetailsPage.route, arguments: mission),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: ScoutColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${mission.type?.label} \n${mission.address}',
                    style: TextStyle(
                      color: ScoutColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  6.verticalSpace,
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 15,
                            color: ScoutColors.primary,
                          ),
                          5.horizontalSpace,
                          Text(
                            '${((mission.durationInSec / 60).round())}min',
                            style: TextStyle(
                              color: ScoutColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      10.horizontalSpace,
                      LocationListenerBuilder(
                        latitude: mission.latitude ?? 0.0,
                        longitude: mission.longitude ?? 0.0,
                        builder: (_, distance) {
                          return Text(
                            '${distance?.formatDistance} away',
                            style: TextStyle(
                              color: ScoutColors.textSecondary,
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            16.horizontalSpace,
            Text(
              mission.formattedPrice,
              style: TextStyle(
                color: ScoutColors.textAccent,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
