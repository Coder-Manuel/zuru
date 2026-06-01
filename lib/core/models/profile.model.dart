import 'package:zuru/core/entities/profile.entity.dart';
import 'package:zuru/core/models/enums.dart';

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
    tags: (data['tags']?.toString() ?? '').split(','),
  );
}
