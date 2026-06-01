import 'package:zuru/core/entities/base.entity.dart';
import 'package:zuru/core/entities/profile.entity.dart';
import 'package:zuru/core/models/enums.dart';

abstract class User extends BaseEntity {
  final String? email;
  final String? phone;
  final UserRole? defaultRole;
  final UserStatus? status;
  final String? fcmToken;
  final bool? isOnline;
  final List<Profile> profiles;

  User({
    super.id,
    super.createdAt,
    super.updatedAt,
    this.email,
    this.phone,
    this.defaultRole,
    this.status,
    this.fcmToken,
    this.isOnline,
    this.profiles = const [],
  });

  Profile? get profile {
    if (profiles.isEmpty) {
      return null;
    }
    return profiles.firstWhere((profile) => profile.role == defaultRole);
  }

  Profile? get clientProfile {
    if (profiles.isEmpty) {
      return null;
    }
    return profiles.firstWhere((profile) => profile.role == UserRole.client);
  }

  Profile? get scoutProfile {
    if (profiles.isEmpty) {
      return null;
    }
    return profiles.firstWhere((profile) => profile.role == UserRole.scout);
  }
}
