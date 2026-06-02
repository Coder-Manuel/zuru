class PlaceSuggestionEntity {
  final String placeId;

  /// Full display text (e.g. "Westlands, Nairobi, Kenya").
  final String description;

  /// Primary part of the address (e.g. "Westlands").
  final String mainText;

  /// Secondary part of the address (e.g. "Nairobi, Kenya").
  final String secondaryText;

  const PlaceSuggestionEntity({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
}
