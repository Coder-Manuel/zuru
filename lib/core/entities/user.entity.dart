import 'package:zuru/core/entities/base.entity.dart';
import 'package:zuru/core/models/enums.dart';

abstract class User extends BaseEntity {
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final UserRole? role;
  final UserStatus? userStatus;
  final String? fcmToken;
  final bool? isOnline;
  final double? rating;
  final int? totalReviews;

  User({
    super.id,
    super.createdAt,
    super.updatedAt,
    this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.role,
    this.userStatus,
    this.fcmToken,
    this.isOnline,
    this.rating,
    this.totalReviews,
  });

  String get displayName {
    final first = firstName ?? '';
    final last = lastName != null && lastName!.isNotEmpty ? lastName![0] : '';
    if (first.isEmpty) return email ?? '';
    return last.isNotEmpty ? '$first $last.' : first;
  }

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}
