import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_theme.dart';
import 'package:zuru/config/scout_theme.dart';

enum ActiveRole { client, scout }

class ThemeService extends GetxService {
  static ThemeService get to => Get.find<ThemeService>();

  final Rx<ActiveRole> role = ActiveRole.client.obs;

  bool get isScout => role.value == ActiveRole.scout;
  bool get isClient => role.value == ActiveRole.client;

  void applyClientTheme() {
    role.value = ActiveRole.client;
    Get.changeTheme(ClientTheme.dark);
  }

  void applyScoutTheme() {
    role.value = ActiveRole.scout;
    Get.changeTheme(ScoutTheme.dark);
  }

  /// Called when the role is determined from the Supabase JWT claim.
  void applyThemeForRole(String? jwtRole) {
    if (jwtRole == 'scout') {
      applyScoutTheme();
    } else {
      applyClientTheme();
    }
  }

  ThemeData get currentTheme =>
      isScout ? ScoutTheme.dark : ClientTheme.dark;
}
