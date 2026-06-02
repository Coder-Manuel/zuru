import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/missions/data/sources/remote_places_datasource.dart';
import 'package:zuru/modules/missions/domain/entities/place_suggestion.entity.dart';
import 'package:zuru/modules/missions/presentation/controllers/post_mission_controller.dart';

class LocationPickerController extends GetxController {
  final _placesDatasource = Get.find<RemotePlacesDatasource>();

  // ── Rate-limiting constants ───────────────────────────────────────────────

  /// How long the camera must be idle before triggering reverse-geocoding.
  static const _idleDebounceDuration = Duration(milliseconds: 1200);

  /// Minimum wall-clock interval between successive reverse-geocode API calls.
  static const _geocodeThrottle = Duration(seconds: 2);

  /// Minimum search-field inactivity before firing the autocomplete API.
  static const _searchDebounceDuration = Duration(milliseconds: 500);

  /// Skip re-geocoding if the pin has not moved more than this many metres
  /// since the last successful call — avoids paying for duplicate requests
  /// when the user taps the same spot repeatedly.
  static const _samePositionThresholdMeters = 5.0;

  // ── State ─────────────────────────────────────────────────────────────────

  final searchCTRL = TextEditingController();

  final RxList<PlaceSuggestionEntity> suggestions =
      <PlaceSuggestionEntity>[].obs;
  final RxBool showSuggestions = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isReverseGeocoding = false.obs;
  final RxBool isFetchingLocation = false.obs;

  /// The address displayed in the bottom confirmation bar.
  final RxString selectedAddress = ''.obs;

  /// Current map centre — kept in sync with every camera movement so that
  /// [confirmLocation] always uses the latest pin position.
  final Rx<LatLng> mapCenter = const LatLng(-1.2676, 36.8108).obs;

  // ── Internals ─────────────────────────────────────────────────────────────

  GoogleMapController? _mapController;
  Timer? _searchDebounce;
  Timer? _idleDebounce;

  /// Centre coordinates of the last successful reverse-geocode call.
  LatLng? _lastGeocodedPosition;

  /// Wall-clock time of the last reverse-geocode API request.
  DateTime? _lastGeocodeAt;

  // ── Initialisation ────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    // Pre-fill with any location already confirmed in PostMissionController.
    final postCtrl = Get.find<PostMissionController>();
    if (postCtrl.hasLocation.value) {
      mapCenter.value = LatLng(
        postCtrl.latitude.value,
        postCtrl.longitude.value,
      );
      selectedAddress.value = postCtrl.address.value;
    }
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // ── Camera callbacks ──────────────────────────────────────────────────────

  /// Fires on every frame while the user is dragging.
  /// Only updates local state — never calls the API.
  void onCameraMove(CameraPosition position) {
    mapCenter.value = position.target;
    // Cancel any pending idle debounce so the geocode timer resets from the
    // moment the camera finally stops, not from when it started moving.
    _idleDebounce?.cancel();
  }

  /// Fires once the camera has fully stopped moving.
  /// Starts the debounce countdown before the reverse-geocode call.
  void onCameraIdle() {
    // Suppress when the autocomplete dropdown is open — the camera may have
    // animated to a tapped suggestion; that path handles geocoding itself.
    if (showSuggestions.value) return;

    _idleDebounce?.cancel();
    _idleDebounce = Timer(_idleDebounceDuration, _maybeReverseGeocode);
  }

  // ── Reverse geocoding (with throttle + distance guard) ────────────────────

  /// Entry point called by the idle debounce timer.
  /// Applies rate-limiting before making the actual API request.
  Future<void> _maybeReverseGeocode() async {
    final center = mapCenter.value;

    // ── Same-position guard ───────────────────────────────────────────────
    // Skip if the pin hasn't moved meaningfully since the last API call —
    // prevents billing for duplicate requests when the user taps the map
    // without really changing the location.
    if (_lastGeocodedPosition != null) {
      final moved = Geolocator.distanceBetween(
        _lastGeocodedPosition!.latitude,
        _lastGeocodedPosition!.longitude,
        center.latitude,
        center.longitude,
      );
      if (moved < _samePositionThresholdMeters) return;
    }

    // ── Time throttle ─────────────────────────────────────────────────────
    // Enforce a hard minimum interval between requests regardless of how
    // quickly the user repositions the pin.
    if (_lastGeocodeAt != null) {
      final elapsed = DateTime.now().difference(_lastGeocodeAt!);
      if (elapsed < _geocodeThrottle) {
        // Reschedule for when the throttle window expires so the most recent
        // pin position is always geocoded eventually.
        final remaining = _geocodeThrottle - elapsed;
        _idleDebounce?.cancel();
        _idleDebounce = Timer(remaining, _maybeReverseGeocode);
        return;
      }
    }

    // All guards passed — record state and make the request.
    _lastGeocodedPosition = center;
    _lastGeocodeAt = DateTime.now();
    await _reverseGeocodeCenter(center);
  }

  Future<void> _reverseGeocodeCenter(LatLng center) async {
    isReverseGeocoding.value = true;
    try {
      final address = await _placesDatasource.reverseGeocode(
        latitude: center.latitude,
        longitude: center.longitude,
      );
      selectedAddress.value = address;
      if (searchCTRL.text.isEmpty) {
        searchCTRL.text = address;
      }
    } catch (_) {
      // Fall back to raw coordinates so the confirm bar always shows something.
      selectedAddress.value =
          '${center.latitude.toStringAsFixed(5)}, '
          '${center.longitude.toStringAsFixed(5)}';
    } finally {
      isReverseGeocoding.value = false;
    }
  }

  // ── Search / autocomplete ─────────────────────────────────────────────────

  void onSearchChanged(String query) {
    _searchDebounce?.cancel();

    if (query.trim().isEmpty) {
      suggestions.clear();
      showSuggestions.value = false;
      return;
    }

    _searchDebounce = Timer(_searchDebounceDuration, () async {
      isSearching.value = true;
      try {
        final results = await _placesDatasource.getAutocompleteSuggestions(
          query: query.trim(),
          latitude: mapCenter.value.latitude,
          longitude: mapCenter.value.longitude,
        );
        suggestions.assignAll(results);
        showSuggestions.value = results.isNotEmpty;
      } catch (_) {
        // Silently fail — the user can still drop a pin.
      } finally {
        isSearching.value = false;
      }
    });
  }

  Future<void> onSuggestionTap(PlaceSuggestionEntity suggestion) async {
    searchCTRL.text = suggestion.mainText;
    showSuggestions.value = false;
    suggestions.clear();
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final details = await _placesDatasource.getPlaceDetails(
        suggestion.placeId,
      );
      final newLatLng = LatLng(details.latitude, details.longitude);

      mapCenter.value = newLatLng;
      selectedAddress.value = details.address;

      // Mark as geocoded so the idle callback that fires after the camera
      // animation does not immediately issue a redundant API request.
      _lastGeocodedPosition = newLatLng;
      _lastGeocodeAt = DateTime.now();

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16));
    } catch (_) {
      Toast.error('Could not load place details. Try again.');
    }
  }

  // ── Current location ──────────────────────────────────────────────────────

  Future<void> useCurrentLocation() async {
    isFetchingLocation.value = true;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        Toast.error(
          'Location permission is permanently denied. Enable it in Settings.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final newLatLng = LatLng(position.latitude, position.longitude);
      mapCenter.value = newLatLng;

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16));

      // Bypass the rate limiter for explicit "use my location" taps — the user
      // expects an immediate address update.
      _lastGeocodedPosition = newLatLng;
      _lastGeocodeAt = DateTime.now();
      await _reverseGeocodeCenter(newLatLng);
      searchCTRL.text = selectedAddress.value;
    } catch (_) {
      Toast.error('Could not get your location. Please try again.');
    } finally {
      isFetchingLocation.value = false;
    }
  }

  // ── Confirm ───────────────────────────────────────────────────────────────

  void confirmLocation() {
    if (selectedAddress.value.isEmpty) {
      Toast.error('No location selected yet. Move the pin or search above.');
      return;
    }

    Get.find<PostMissionController>().setLocation(
      address: selectedAddress.value,
      latitude: mapCenter.value.latitude,
      longitude: mapCenter.value.longitude,
    );

    Get.back();
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  @override
  void onClose() {
    _searchDebounce?.cancel();
    _idleDebounce?.cancel();
    searchCTRL.dispose();
    _mapController?.dispose();
    super.onClose();
  }
}
