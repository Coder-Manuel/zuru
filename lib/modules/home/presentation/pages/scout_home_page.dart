import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/modules/alerts/presentation/controllers/alerts_controller.dart';
import 'package:zuru/modules/alerts/presentation/pages/alerts_tab.dart';
import 'package:zuru/modules/home/presentation/controllers/home_controller.dart';
import 'package:zuru/modules/missions/presentation/pages/scout_missions_tab.dart';
import 'package:zuru/modules/missions/presentation/pages/radar_page.dart';
import 'package:zuru/modules/user/presentation/pages/profile_page.dart';

class ScoutHomePage extends GetView<HomeController> {
  static const String route = '/scout/home';

  const ScoutHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScoutColors.background,
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: [
            const RadarPage(),
            const ScoutMissionsTab(),
            const AlertsTab(),
            ProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(controller: controller),
    );
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final HomeController controller;

  const _BottomNav({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final idx = controller.currentIndex.value;

      return Container(
        decoration: BoxDecoration(
          color: ScoutColors.background,
          border: Border(top: BorderSide(color: ScoutColors.divider, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.map_outlined,
                  label: 'RADAR',
                  active: idx == 0,
                  onTap: () => controller.onTabTapped(0),
                ),
                _NavItem(
                  icon: Icons.assignment_outlined,
                  label: 'TASKS',
                  active: idx == 1,
                  onTap: () => controller.onTabTapped(1),
                ),
                Obx(
                  () => _NavItem(
                    icon: Icons.notifications_outlined,
                    label: 'ALERTS',
                    active: idx == 2,
                    badgeCount: Get.find<AlertsController>().unreadCount,
                    onTap: () => controller.onTabTapped(2),
                  ),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  label: 'PROFILE',
                  active: idx == 3,
                  onTap: () => controller.onTabTapped(3),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? ScoutColors.primary : ScoutColors.iconColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: ScoutColors.scoutMarker,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: ScoutColors.background,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
