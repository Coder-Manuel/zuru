import 'package:dio/dio.dart';
import 'package:zuru/config/env.dart';
import 'package:zuru/modules/missions/data/models/place_suggestion.model.dart';
import 'package:zuru/modules/missions/domain/entities/place_suggestion.entity.dart';

abstract class RemotePlacesDatasource {
  /// Returns autocomplete suggestions from the Google Places API.
  Future<List<PlaceSuggestionEntity>> getAutocompleteSuggestions({
    required String query,
    required double latitude,
    required double longitude,
  });

  /// Returns the lat/lng for a given [placeId] via the Places Details API.
  Future<({double latitude, double longitude, String address})> getPlaceDetails(
    String placeId,
  );

  /// Reverse-geocodes [latitude]/[longitude] to a human-readable address.
  Future<String> reverseGeocode({
    required double latitude,
    required double longitude,
  });
}

class RemotePlacesDatasourceImpl extends RemotePlacesDatasource {
  final Dio _dio;

  static const _baseUrl = 'https://maps.googleapis.com/maps/api';
  static const _autocompleteEndpoint = '/place/autocomplete/json';
  static const _detailsEndpoint = '/place/details/json';
  static const _geocodeEndpoint = '/geocode/json';

  RemotePlacesDatasourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<PlaceSuggestionEntity>> getAutocompleteSuggestions({
    required String query,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl$_autocompleteEndpoint',
      queryParameters: {
        'input': query,
        'location': '$latitude,$longitude',
        'radius': 50000, // 50 km bias radius
        'key': Env.googleMapsApiKey,
      },
    );

    final predictions = (response.data?['predictions'] as List<dynamic>?) ?? [];

    return predictions
        .cast<Map<String, dynamic>>()
        .map(PlaceSuggestionModel.fromMap)
        .toList();
  }

  @override
  Future<({double latitude, double longitude, String address})> getPlaceDetails(
    String placeId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl$_detailsEndpoint',
      queryParameters: {
        'place_id': placeId,
        'fields': 'geometry,formatted_address',
        'key': Env.googleMapsApiKey,
      },
    );

    final result = response.data?['result'] as Map<String, dynamic>?;
    final location =
        (result?['geometry'] as Map<String, dynamic>?)?['location']
            as Map<String, dynamic>?;

    return (
      latitude: (location?['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (location?['lng'] as num?)?.toDouble() ?? 0.0,
      address: result?['formatted_address'] as String? ?? '',
    );
  }

  @override
  Future<String> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl$_geocodeEndpoint',
      queryParameters: {
        'latlng': '$latitude,$longitude',
        'key': Env.googleMapsApiKey,
      },
    );

    final results = (response.data?['results'] as List<dynamic>?) ?? [];
    if (results.isEmpty) return '$latitude, $longitude';

    return (results.first as Map<String, dynamic>)['formatted_address']
            as String? ??
        '$latitude, $longitude';
  }
}
