import 'package:zuru/core/entities/profile_clip.entity.dart';

class ProfileClipModel extends ProfileClip {
  ProfileClipModel({
    super.id,
    super.createdAt,
    super.updatedAt,
    super.profileId,
    super.title,
    super.mediaUrl,
  });

  factory ProfileClipModel.fromMap(Map<String, dynamic> data) =>
      ProfileClipModel(
        id: data['id']?.toString(),
        createdAt: data['created_at']?.toString(),
        updatedAt: data['updated_at']?.toString(),
        profileId: data['profile_id']?.toString(),
        title: data['title']?.toString(),
        mediaUrl: data['media_url']?.toString(),
      );

  /// Payload for inserting a new clip row. Omits `id`/timestamps so the DB can
  /// manage them.
  Map<String, dynamic> toInsertMap() => {
    'profile_id': profileId,
    if (title != null) 'title': title,
    if (mediaUrl != null) 'media_url': mediaUrl,
  };
}
