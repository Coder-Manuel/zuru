import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_theme.dart';
import 'package:zuru/config/scout_theme.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/services/storage_service/storage.service.dart';

class RoleService extends GetxService {
  static RoleService get instance => Get.find<RoleService>();

  final Rx<UserRole> role = UserRole.client.obs;

  bool get isScout => role.value == UserRole.scout;
  bool get isClient => role.value == UserRole.client;

  /// Restores the last saved role on every cold start.
  @override
  Future<void> onInit() async {
    super.onInit();
    final saved = await StorageService.get<String>(StorageKeys.roleKey);
    if (saved == UserRole.scout.name) {
      _apply(UserRole.scout);
    } else {
      _apply(UserRole.client);
    }
  }

  void applyClientTheme() {
    _apply(UserRole.client);
    StorageService.save(StorageKeys.roleKey, value: UserRole.client.name);
  }

  void applyScoutTheme() {
    _apply(UserRole.scout);
    StorageService.save(StorageKeys.roleKey, value: UserRole.scout.name);
  }

  void setRole(UserRole? role) {
    log('===== NEW ROLE: $role');
    if (role == null) return;
    if (role == UserRole.scout) {
      applyScoutTheme();
    } else {
      applyClientTheme();
    }
  }

  ThemeData get currentTheme => isScout ? ScoutTheme.dark : ClientTheme.dark;

  // ── Private ───────────────────────────────────────────────────────────────
  void _apply(UserRole r) {
    role.value = r;
    Get.changeThemeMode(r == UserRole.scout ? ThemeMode.light : ThemeMode.dark);
  }
}
