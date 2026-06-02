import 'package:zuru/modules/rating/domain/entities/rating.entity.dart';

class RatingModel extends RatingEntity {
  RatingModel({
    super.id,
    super.createdAt,
    super.missionId,
    super.fromUserId,
    super.toUserId,
    required super.score,
    super.comment,
  });

  factory RatingModel.fromMap(Map<String, dynamic> data) => RatingModel(
    id: data['id']?.toString(),
    createdAt: data['created_at']?.toString(),
    missionId: data['mission_id']?.toString(),
    fromUserId: data['from_user_id']?.toString(),
    toUserId: data['to_user_id']?.toString(),
    score: data['score'] as int? ?? 0,
    comment: data['comment']?.toString(),
  );
}
