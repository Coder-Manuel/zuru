import 'package:zuru/modules/missions/domain/entities/place_suggestion.entity.dart';

class PlaceSuggestionModel extends PlaceSuggestionEntity {
  const PlaceSuggestionModel({
    required super.placeId,
    required super.description,
    required super.mainText,
    required super.secondaryText,
  });

  factory PlaceSuggestionModel.fromMap(Map<String, dynamic> map) {
    final structured = map['structured_formatting'] as Map<String, dynamic>? ?? {};
    return PlaceSuggestionModel(
      placeId: map['place_id'] as String? ?? '',
      description: map['description'] as String? ?? '',
      mainText: structured['main_text'] as String? ?? '',
      secondaryText: structured['secondary_text'] as String? ?? '',
    );
  }
}
