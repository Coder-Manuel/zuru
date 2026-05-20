class CreateRatingInput {
  /// The mission this rating belongs to.
  final String missionId;

  /// The user being rated (the scout).
  final String toUserId;

  /// Score from 1 to 5.
  final int score;

  /// Optional written feedback.
  final String? comment;

  CreateRatingInput({
    required this.missionId,
    required this.toUserId,
    required this.score,
    this.comment,
  }) : assert(score >= 1 && score <= 5, 'score must be between 1 and 5');

  Map<String, dynamic> toMap() => {
    'mission_id': missionId,
    'to_user_id': toUserId,
    'score': score,
    if (comment != null && comment!.isNotEmpty) 'comment': comment,
  };
}
