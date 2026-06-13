import 'package:zuru/core/entities/profile_clip.entity.dart';
import 'package:zuru/core/models/enums.dart';

class ProfileClipModel extends ProfileClip {
  ProfileClipModel({
    super.id,
    super.createdAt,
    super.updatedAt,
    super.profileId,
    required super.type,
    super.title,
    super.mediaUrl,
  });

  factory ProfileClipModel.fromMap(Map<String, dynamic> data) =>
      ProfileClipModel(
        id: data['id']?.toString(),
        createdAt: data['created_at']?.toString(),
        updatedAt: data['updated_at']?.toString(),
        profileId: data['profile_id']?.toString(),
        type: ClipType.values.firstWhere(
          (t) => t.name == data['type'],
          orElse: () => ClipType.personal,
        ),
        title: data['title']?.toString(),
        mediaUrl: data['media_url']?.toString(),
      );

  /// Payload for an upsert into `profile_clips`. Omits `id`/timestamps so the
  /// DB can manage them; relies on the unique `(profile_id, type)` constraint.
  Map<String, dynamic> toUpsertMap() => {
    'profile_id': profileId,
    'type': type.name,
    if (title != null) 'title': title,
    if (mediaUrl != null) 'media_url': mediaUrl,
  };
}
