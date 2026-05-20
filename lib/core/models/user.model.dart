import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/models/enums.dart';

class UserModel extends User {
  UserModel({
    super.id,
    super.createdAt,
    super.updatedAt,
    super.email,
    super.firstName,
    super.lastName,
    super.phone,
    super.role,
    super.userStatus,
    super.fcmToken,
    super.isOnline,
    super.rating,
    super.totalReviews,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) => UserModel(
    id: data['id']?.toString(),
    createdAt: data['created_at']?.toString(),
    updatedAt: data['updated_at']?.toString(),
    email: data['email']?.toString(),
    firstName: data['first_name']?.toString(),
    lastName: data['last_name']?.toString(),
    phone: data['phone']?.toString(),
    role: UserRole.values.firstWhere(
      (v) => v.name == data['role'],
      orElse: () => UserRole.client,
    ),
    userStatus: UserStatus.values.firstWhere(
      (s) => s.name == data['status'],
      orElse: () => UserStatus.inactive,
    ),
    fcmToken: data['fcm_token']?.toString(),
    isOnline: data['is_online'] as bool?,
    rating: (data['rating'] as num?)?.toDouble(),
    totalReviews: data['total_reviews'] as int?,
  );
}
