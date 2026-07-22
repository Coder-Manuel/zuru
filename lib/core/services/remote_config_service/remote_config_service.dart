import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/core/services/storage_service/storage.service.dart';
import 'package:zuru/core/utils/error_wrapper.dart';

/// Backend-driven app configuration.
///
/// Reads a generic key/value (jsonb) `app_config` table so values can change
/// server-side without an app release. Loads the cached snapshot immediately,
/// fetches fresh on boot, then re-syncs every 2 hours while the app is open.
///
/// Callers read a section via [section] and parse it into their own typed model
/// (always with a hard-coded fallback so the app works offline / pre-first-sync).
class RemoteConfigService extends GetxService {
  static const _library = 'RemoteConfigService';
  static const _refreshInterval = Duration(hours: 2);

  final SupabaseClient _client;
  RemoteConfigService({required SupabaseClient client}) : _client = client;

  final RxMap<String, dynamic> values = <String, dynamic>{}.obs;
  final Rxn<DateTime> lastUpdated = Rxn<DateTime>();

  Timer? _timer;
  StreamSubscription<AuthState>? _authSub;

  @override
  void onInit() {
    super.onInit();
    _loadCached();
    // app_config is readable only by authenticated users, so (re)sync whenever a
    // session is present — covers the restored session on boot and fresh logins.
    _authSub = _client.auth.onAuthStateChange.listen((state) {
      if (state.session != null) refresh();
    });
    _timer = Timer.periodic(_refreshInterval, (_) => refresh());
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _timer?.cancel();
    super.onClose();
  }

  /// Returns the jsonb object stored under [key], or null when absent.
  Map<String, dynamic>? section(String key) {
    final value = values[key];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  Future<void> refresh() async {
    await ErrorWrapper.async<void>(
      () async {
        final rows = await _client.from('app_config').select('key, value');
        final map = <String, dynamic>{};
        for (final row in rows) {
          final key = row['key']?.toString();
          if (key != null) map[key] = row['value'];
        }
        values.assignAll(map);
        lastUpdated.value = DateTime.now();
        await _cache(map);
        log('App config synced (${map.length} keys)', name: _library);
      },
      library: _library,
      description: 'while fetching app config',
    );
  }

  Future<void> _loadCached() async {
    final cached = await StorageService.get<Map>(StorageKeys.appConfigKey);
    if (cached != null) {
      values.assignAll(Map<String, dynamic>.from(cached));
    }
  }

  Future<void> _cache(Map<String, dynamic> map) async {
    await StorageService.save<Map<String, dynamic>>(
      StorageKeys.appConfigKey,
      value: map,
    );
  }
}
