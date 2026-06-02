import 'package:zuru/core/entities/profile.entity.dart';
import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/models/profile.model.dart';

class UserModel extends User {
  UserModel({
    super.id,
    super.createdAt,
    super.updatedAt,
    super.email,
    super.phone,
    super.defaultRole,
    super.status,
    super.fcmToken,
    super.isOnline,
    super.profiles,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) => UserModel(
    id: data['id']?.toString(),
    createdAt: data['created_at']?.toString(),
    updatedAt: data['updated_at']?.toString(),
    email: data['email']?.toString(),
    phone: data['phone']?.toString(),
    defaultRole: UserRole.values.firstWhere(
      (v) => v.name == data['default_role'],
      orElse: () => UserRole.client,
    ),
    status: UserStatus.values.firstWhere(
      (s) => s.name == data['status'],
      orElse: () => UserStatus.inactive,
    ),
    fcmToken: data['fcm_token']?.toString(),
    isOnline: data['is_online'] as bool?,
    profiles:
        data['profiles']
            ?.map<Profile>((data) => ProfileModel.fromMap(data))
            .toList() ??
        [],
  );
}
