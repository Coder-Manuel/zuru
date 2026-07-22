import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:zuru/core/services/storage_service/storage.service.dart';
import 'package:zuru/core/utils/error_wrapper.dart';

/// Currencies the app can price a live check in.
enum Currency {
  usd,
  kes;

  /// ISO code stored on the mission (`currency` column).
  String get code => switch (this) {
    Currency.usd => 'USD',
    Currency.kes => 'KES',
  };

  String get symbol => switch (this) {
    Currency.usd => '\$',
    Currency.kes => 'KSh',
  };

  static Currency fromCode(String? code) => switch (code?.toUpperCase()) {
    'KES' => Currency.kes,
    _ => Currency.usd,
  };
}

/// Foreign-exchange service — the single source of truth for the USD → KES rate.
///
/// - Loads the last cached rate immediately (so the UI is never blank).
/// - Fetches a fresh rate on boot, then every hour while the app is open.
/// - Rates are rounded to the nearest whole number, per product requirement.
///
/// Registered as a permanent [GetxService] in InitialBinding; its work runs from
/// [onInit]. Rates are read reactively via [usdToKes].
class FxService extends GetxService {
  static const _library = 'FxService';

  /// Free, key-less USD-base rates endpoint (includes KES). This returns the
  /// **mid-market** (interbank) rate — the true midpoint with no margin.
  static const _endpoint = 'https://open.er-api.com/v6/latest/USD';
  static const _refreshInterval = Duration(hours: 1);

  /// Retail markup applied over the mid-market rate so displayed KES lands close
  /// to what Kenyan banking / mobile-money platforms actually quote (they add a
  /// spread of ~1.5–3% over mid-market on the sell side). 1.02 ≈ +2%.
  /// Tune this single value to calibrate against a specific platform.
  static const double _retailSpread = 1.005;

  /// Applies the retail spread and rounds to the nearest whole number.
  static double _toRetail(num midMarket) =>
      (midMarket * _retailSpread).roundToDouble();

  /// Sane offline mid-market default until the first successful fetch/cache load.
  static const double _fallbackMidUsdToKes = 129;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// USD → KES **retail** rate (mid-market + [_retailSpread]), rounded to the
  /// nearest whole number. Reactive.
  final RxDouble usdToKes = _toRetail(_fallbackMidUsdToKes).obs;

  /// When the live rate was last refreshed successfully.
  final Rxn<DateTime> lastUpdated = Rxn<DateTime>();

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
    _timer = Timer.periodic(_refreshInterval, (_) => refresh());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    await _loadCached();
    await refresh();
  }

  /// Converts a USD amount to whole KES using the current rate.
  int toKes(num usd) => (usd * usdToKes.value).round();

  /// Converts between supported currencies, rounded to a whole number.
  int convert(num amount, Currency from, Currency to) =>
      convertPrecise(amount, from, to).round();

  /// Converts between supported currencies without rounding — callers decide how
  /// to display (e.g. USD keeps decimals so small values don't collapse to \$0).
  double convertPrecise(num amount, Currency from, Currency to) {
    if (from == to) return amount.toDouble();
    return switch ((from, to)) {
      (Currency.usd, Currency.kes) => amount * usdToKes.value,
      (Currency.kes, Currency.usd) => amount / usdToKes.value,
      _ => amount.toDouble(),
    };
  }

  /// Fetches the latest USD → KES rate and caches it. Keeps the last known value
  /// on any failure so the UI degrades gracefully.
  Future<void> refresh() async {
    await ErrorWrapper.async<void>(
      () async {
        final res = await _dio.get<dynamic>(_endpoint);
        final data = res.data;
        final rates = data is Map ? data['rates'] : null;
        final kes = rates is Map ? rates['KES'] : null;

        if (kes is num && kes > 0) {
          final retail = _toRetail(kes);
          usdToKes.value = retail;
          lastUpdated.value = DateTime.now();
          await _cache(retail);
          log(
            'USD → KES retail updated: ${retail.toInt()} '
            '(mid ${kes.toStringAsFixed(2)} × $_retailSpread)',
            name: _library,
          );
        }
      },
      library: _library,
      description: 'while fetching USD → KES rate',
    );
  }

  Future<void> _loadCached() async {
    final cached = await StorageService.get<Map>(StorageKeys.fxRatesKey);
    final rate = cached?['usd_kes'];
    if (rate is num && rate > 0) {
      usdToKes.value = rate.toDouble();
      final ts = cached?['updated_at'];
      if (ts is String) lastUpdated.value = DateTime.tryParse(ts);
    }
  }

  Future<void> _cache(double rate) async {
    await StorageService.save<Map<String, dynamic>>(
      StorageKeys.fxRatesKey,
      value: {'usd_kes': rate, 'updated_at': DateTime.now().toIso8601String()},
    );
  }
}
