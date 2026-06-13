import 'package:get/get.dart';
import 'package:zuru/core/entities/base.entity.dart';
import 'package:zuru/core/entities/profile_clip.entity.dart';
import 'package:zuru/core/entities/session_pricing.entity.dart';
import 'package:zuru/core/models/enums.dart';

abstract class Profile extends BaseEntity {
  final String? firstName;
  final String? lastName;
  final UserRole? role;
  final UserStatus? status;
  final double? rating;
  final int? totalReviews;
  final String? bio;
  final String? userId;
  final List<String> tags;

  // ── Scout World Profile ────────────────────────────────────────────────────
  final String? avatarUrl;
  final String? locality;
  final ScoutAvailability? availability;
  final List<SessionPricing> sessionPricing;
  final List<ProfileClip> clips;

  // ── Scout performance stats (nullable until tracked server-side) ────────────
  /// Fraction in 0..1 (e.g. 0.95 → 95%).
  final double? fulfillmentRate;

  /// Average response time in minutes.
  final double? avgResponseMinutes;

  /// Languages the scout speaks.
  final List<String> languages;

  Profile({
    super.id,
    super.createdAt,
    super.updatedAt,
    this.firstName,
    this.lastName,
    this.role,
    this.status,
    this.rating,
    this.totalReviews,
    this.bio,
    this.userId,
    this.tags = const [],
    this.avatarUrl,
    this.locality,
    this.availability,
    this.sessionPricing = const [],
    this.clips = const [],
    this.fulfillmentRate,
    this.avgResponseMinutes,
    this.languages = const [],
  });

  String get displayName {
    final first = firstName ?? '';
    final last = lastName != null && lastName!.isNotEmpty ? lastName![0] : '';
    if (first.isEmpty) return 'Anonymous';
    return last.isNotEmpty ? '$first $last.' : first;
  }

  String get fullName =>
      '${firstName?.capitalizeFirst ?? ''} ${lastName?.capitalizeFirst ?? ''}'
          .trim();
}
