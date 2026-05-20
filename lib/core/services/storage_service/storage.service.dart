import 'dart:developer';

import 'package:get_storage/get_storage.dart';

enum StorageKeys {
  onBoardKey,
  userDataKey,
  emailKey,
  passwordKey,
  biometricsKey,
  notificationKey,
}

class StorageService {
  static late GetStorage _storage;

  static Future<void> init([String container = 'zuru_world']) async {
    await GetStorage.init(container);
    _storage = GetStorage(container);
    log('Storage Service Initialized');
  }

  static Future<void> save<T>(StorageKeys key, {required T value}) =>
      _storage.write(key.name, value);

  static Future<T?> get<T>(StorageKeys key) async =>
      _storage.read<T>(key.name);

  static Future<void> remove(StorageKeys key) => _storage.remove(key.name);

  static Future<bool> contains<T>(StorageKeys key) async {
    final value = await get<T>(key);
    if (value == null) return false;
    if (value is String && value.isEmpty) return false;
    return true;
  }

  static Future<void> removeAll() async {
    for (var key in StorageKeys.values) {
      await remove(key);
    }
  }
}
