import 'package:zuru/core/entities/base.entity.dart';
import 'package:zuru/core/models/enums.dart';

/// A media clip attached to a scout's World Profile.
///
/// Backed by the dedicated `profile_clips` table (unique on
/// `(profile_id, type)`), one row per [ClipType] slot.
abstract class ProfileClip extends BaseEntity {
  final String? profileId;
  final ClipType type;
  final String? title;
  final String? mediaUrl;

  ProfileClip({
    super.id,
    super.createdAt,
    super.updatedAt,
    this.profileId,
    required this.type,
    this.title,
    this.mediaUrl,
  });
}
