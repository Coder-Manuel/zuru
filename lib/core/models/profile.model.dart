import 'package:zuru/core/entities/profile.entity.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/models/profile_clip.model.dart';
import 'package:zuru/core/models/session_pricing.model.dart';

class ProfileModel extends Profile {
  ProfileModel({
    super.id,
    super.createdAt,
    super.updatedAt,
    super.firstName,
    super.lastName,
    super.role,
    super.status,
    super.rating,
    super.totalReviews,
    super.bio,
    super.tags,
    super.userId,
    super.avatarUrl,
    super.locality,
    super.availability,
    super.sessionPricing,
    super.clips,
    super.fulfillmentRate,
    super.avgResponseMinutes,
    super.languages,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> data) => ProfileModel(
    id: data['id']?.toString(),
    createdAt: data['created_at']?.toString(),
    updatedAt: data['updated_at']?.toString(),
    firstName: data['first_name']?.toString(),
    lastName: data['last_name']?.toString(),
    role: UserRole.values.firstWhere(
      (v) => v.name == data['role'],
      orElse: () => UserRole.client,
    ),
    status: UserStatus.values.firstWhere(
      (s) => s.name == data['status'],
      orElse: () => UserStatus.inactive,
    ),
    rating: (data['rating'] as num?)?.toDouble(),
    totalReviews: data['total_reviews'] as int?,
    bio: data['bio']?.toString(),
    userId: data['user_id']?.toString(),
    tags: _parseTags(data['tags']),
    avatarUrl: data['avatar_url']?.toString(),
    locality: data['locality_address']?.toString(),
    availability: data['availability'] == null
        ? null
        : ScoutAvailability.values.firstWhere(
            (a) => a.name == data['availability'],
            orElse: () => ScoutAvailability.offline,
          ),
    sessionPricing: _parsePricing(data['session_pricing']),
    clips: _parseClips(data['profile_clips']),
    fulfillmentRate: (data['fulfillment_rate'] as num?)?.toDouble(),
    avgResponseMinutes: (data['avg_response_minutes'] as num?)?.toDouble(),
    languages: _parseLanguages(data['languages']),
  );

  static List<String> _parseLanguages(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is String && raw.isNotEmpty) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static List<String> _parseTags(dynamic raw) {
    if (raw == null) return const [];
    return raw
        .toString()
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  static List<SessionPricingModel> _parsePricing(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => SessionPricingModel.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  static List<ProfileClipModel> _parseClips(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => ProfileClipModel.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }
}
