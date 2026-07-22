import 'package:zuru/core/services/fx_service/fx_service.dart';

class MissionPricingConfig {
  final Currency baseCurrency;
  final List<int> durations;
  final Map<int, List<int>> options;

  const MissionPricingConfig({
    required this.baseCurrency,
    required this.durations,
    required this.options,
  });

  static const fallback = MissionPricingConfig(
    baseCurrency: Currency.usd,
    durations: [10, 15, 20, 30, 45, 60],
    options: {
      10: [3, 4, 5],
      15: [5, 7, 9],
      20: [8, 10, 13],
      30: [13, 17, 22],
      45: [18, 24, 30],
      60: [25, 32, 40],
    },
  );

  factory MissionPricingConfig.fromSection(Map<String, dynamic>? section) {
    final tiers = section?['tiers'];
    if (tiers is! List || tiers.isEmpty) return fallback;

    final baseCurrency = Currency.fromCode(
      section?['currency_base']?.toString(),
    );
    final durations = <int>[];
    final options = <int, List<int>>{};

    for (final tier in tiers) {
      if (tier is! Map) continue;
      final minutes = (tier['duration_minutes'] as num?)?.toInt();
      final tierOptions = tier['options'];
      if (minutes == null || tierOptions is! List) continue;

      final parsed = tierOptions
          .whereType<num>()
          .map((e) => e.toInt())
          .toList();
      if (parsed.isEmpty) continue;

      durations.add(minutes);
      options[minutes] = parsed;
    }

    if (durations.isEmpty) return fallback;
    durations.sort();
    return MissionPricingConfig(
      baseCurrency: baseCurrency,
      durations: durations,
      options: options,
    );
  }
}
