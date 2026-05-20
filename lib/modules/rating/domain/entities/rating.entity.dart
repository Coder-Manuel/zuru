import 'package:zuru/core/entities/base.entity.dart';

class RatingEntity extends BaseEntity {
  final String? missionId;
  final String? fromUserId;
  final String? toUserId;

  /// Score out of 5.
  final int score;
  final String? comment;

  RatingEntity({
    super.id,
    super.createdAt,
    this.missionId,
    this.fromUserId,
    this.toUserId,
    required this.score,
    this.comment,
  });

}
