import 'package:zuru/core/entities/session_pricing.entity.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/models/session_pricing.model.dart';

/// Mutable payload describing the editable fields of a scout's World Profile.
///
/// Maps 1:1 onto the `profiles` table columns when serialized via [toMap].
class ScoutProfileEditInput {
  final String bio;
  final List<String> tags;
  final String? locality;
  final ScoutAvailability availability;
  final String? avatarUrl;
  final List<SessionPricing> sessionPricing;

  const ScoutProfileEditInput({
    required this.bio,
    required this.tags,
    required this.locality,
    required this.availability,
    required this.avatarUrl,
    required this.sessionPricing,
  });

  Map<String, dynamic> toMap() => {
    'bio': bio,
    'tags': tags.join(','),
    'locality': locality,
    'availability': availability.name,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    'session_pricing': sessionPricing
        .map((p) => SessionPricingModel.fromEntity(p).toMap())
        .toList(),
  };
}
