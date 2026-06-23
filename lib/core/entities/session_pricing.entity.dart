/// A single scout session-pricing tier (e.g. "10 min session — KES 800").
///
/// Persisted as one element of the `session_pricing` JSONB array on the
/// `profiles` table.
class SessionPricing {
  final int durationMinutes;
  final num price;
  final String currency;

  const SessionPricing({
    required this.durationMinutes,
    required this.price,
    this.currency = 'KES',
  });

  /// Human label used in the UI, e.g. "10 min session".
  String get label => '$durationMinutes min session';

  SessionPricing copyWith({
    int? durationMinutes,
    num? price,
    String? currency,
  }) {
    return SessionPricing(
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      currency: currency ?? this.currency,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SessionPricing && other.durationMinutes == durationMinutes;

  @override
  int get hashCode => durationMinutes.hashCode;
}
