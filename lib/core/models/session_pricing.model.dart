import 'package:zuru/core/entities/session_pricing.entity.dart';

class SessionPricingModel extends SessionPricing {
  const SessionPricingModel({
    required super.durationMinutes,
    required super.price,
    super.currency,
  });

  factory SessionPricingModel.fromMap(Map<String, dynamic> data) =>
      SessionPricingModel(
        durationMinutes: (data['duration_minutes'] as num?)?.toInt() ?? 0,
        price: (data['price'] as num?) ?? 0,
        currency: data['currency']?.toString() ?? 'KES',
      );

  Map<String, dynamic> toMap() => {
    'duration_minutes': durationMinutes,
    'price': price,
    'currency': currency,
  };

  factory SessionPricingModel.fromEntity(SessionPricing e) =>
      SessionPricingModel(
        durationMinutes: e.durationMinutes,
        price: e.price,
        currency: e.currency,
      );
}
