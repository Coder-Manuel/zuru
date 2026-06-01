import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/core/routes/app_routes.dart';

class JoinStreamDialog extends StatelessWidget {
  final MissionEntity mission;

  const JoinStreamDialog({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ClientColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ────────────────────────────────────────────────────────
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ClientColors.primary.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.videocam_rounded,
                color: ClientColors.primary,
                size: 32,
              ),
            ),

            const SizedBox(height: 16),

            // ── Title ────────────────────────────────────────────────────────
            Text(
              'Scout ${mission.scout?.firstName ?? ''} is Live!',
              style: TextStyle(
                color: ClientColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            // ── Subtitle ─────────────────────────────────────────────────────
            Text(
              mission.address,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ClientColors.textSecondary,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // ── Description ──────────────────────────────────────────────────
            Text(
              'Your scout has started streaming. Join now to watch the live feed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ClientColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // ── Action buttons ───────────────────────────────────────────────
            Row(
              children: [
                // Later
                Expanded(
                  child: OutlinedButton(
                    onPressed: Get.back,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ClientColors.textSecondary,
                      side: BorderSide(color: ClientColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Later',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Join Now
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      // StreamRoleMiddleware renders JoinStreamPage for clients.
                      Get.toNamed(AppRoutes.stream, arguments: mission);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClientColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Join Now',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
