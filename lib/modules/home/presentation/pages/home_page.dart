import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/modules/home/presentation/pages/tabs/maps_tab.dart';
import 'package:zuru/modules/missions/presentation/pages/missions_tab.dart';
import 'package:zuru/modules/home/presentation/pages/tabs/notifications_tab.dart';
import 'package:zuru/modules/user/presentation/pages/settings_tab.dart';
import 'package:zuru/modules/home/presentation/controllers/home_controller.dart';

class HomePage extends GetView<HomeController> {
  static const String route = '/home';

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        return IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            MapsTab(),
            MissionsTab(),
            NotificationsTab(),
            SettingsTab(),
          ],
        );
      }),
      bottomNavigationBar: Obx(
        () => Container(
          decoration: BoxDecoration(
            color: ClientColors.surface,
            border: Border(
              top: BorderSide(color: ClientColors.divider, width: 0.5),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changePage,
            backgroundColor: ClientColors.surface,
            selectedItemColor: ClientColors.primary,
            unselectedItemColor: ClientColors.textSecondary,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'MAP',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.my_location_outlined),
                activeIcon: Icon(Icons.my_location),
                label: 'MISSIONS',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_outlined),
                activeIcon: Icon(Icons.notifications),
                label: 'ALERTS',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'PROFILE',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
