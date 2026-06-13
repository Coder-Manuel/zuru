import 'package:zuru/core/entities/base.entity.dart';

/// A media clip attached to a scout's World Profile.
///
/// Backed by the `profile_clips` table — a scout may add up to 3 free-form
/// clips (no fixed category).
abstract class ProfileClip extends BaseEntity {
  final String? profileId;
  final String? title;
  final String? mediaUrl;

  ProfileClip({
    super.id,
    super.createdAt,
    super.updatedAt,
    this.profileId,
    this.title,
    this.mediaUrl,
  });
}
