import 'package:zuru/core/entities/base.entity.dart';
import 'package:zuru/core/models/enums.dart';

abstract class Profile extends BaseEntity {
  final String? firstName;
  final String? lastName;
  final UserRole? role;
  final UserStatus? status;
  final double? rating;
  final int? totalReviews;
  final String? bio;
  final List<String> tags;

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
    this.tags = const [],
  });

  String get displayName {
    final first = firstName ?? '';
    final last = lastName != null && lastName!.isNotEmpty ? lastName![0] : '';
    if (first.isEmpty) return 'Anonymous';
    return last.isNotEmpty ? '$first $last.' : first;
  }

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}
