import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_theme.dart';
import 'package:zuru/config/scout_theme.dart';
import 'package:zuru/core/services/storage_service/storage.service.dart';

enum ActiveRole { client, scout }

class ThemeService extends GetxService {
  static ThemeService get to => Get.find<ThemeService>();

  final Rx<ActiveRole> role = ActiveRole.client.obs;

  bool get isScout => role.value == ActiveRole.scout;
  bool get isClient => role.value == ActiveRole.client;

  /// Restores the last saved role on every cold start.
  @override
  Future<void> onInit() async {
    super.onInit();
    final saved = await StorageService.get<String>(StorageKeys.roleKey);
    if (saved == ActiveRole.scout.name) {
      _apply(ActiveRole.scout);
    } else {
      _apply(ActiveRole.client);
    }
  }

  void applyClientTheme() {
    _apply(ActiveRole.client);
    StorageService.save(StorageKeys.roleKey, value: ActiveRole.client.name);
  }

  void applyScoutTheme() {
    _apply(ActiveRole.scout);
    StorageService.save(StorageKeys.roleKey, value: ActiveRole.scout.name);
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

  // ── Private ───────────────────────────────────────────────────────────────

  void _apply(ActiveRole r) {
    role.value = r;
    Get.changeTheme(r == ActiveRole.scout ? ScoutTheme.dark : ClientTheme.dark);
  }
}
