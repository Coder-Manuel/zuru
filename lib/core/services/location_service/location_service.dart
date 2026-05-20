import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/core/utils/error_wrapper.dart';
import 'package:zuru/core/utils/extensions.dart';

class LocationService extends GetxService with WidgetsBindingObserver {
  final String _library = 'Location Service';

  LocationService({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  final SupabaseClient _supabase;

  static const _kUpdateInterval = Duration(seconds: 25);
  static const _kLocationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 30,
  );

  final position = Rx<Position?>(null);
  final isReady = false.obs;
  final error = Rx<String?>(null);

  Timer? _periodicTimer;

  static const double missionProximityMeters = 100.0;

  double? get latitude => position.value?.latitude;
  double? get longitude => position.value?.longitude;

  double? distanceTo(double targetLat, double targetLng) {
    final pos = position.value;
    if (pos == null) return null;
    return Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      targetLat,
      targetLng,
    );
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initLocation();
  }

  @override
  void onClose() {
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (isReady.value) {
          _fetchAndSubmit();
          _startTimer();
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopTimer();
    }
  }

  Future<void> retryInit() => _initLocation();

  Future<void> _initLocation() async {
    error.value = null;
    isReady.value = false;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      error.value = 'Location services are disabled.';
      return;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.deniedForever) {
      error.value =
          'Location permission permanently denied. Enable it in Settings.';
      return;
    }
    if (perm == LocationPermission.denied) {
      error.value = 'Location permission denied.';
      return;
    }

    final ok = await _fetchAndSubmit();
    if (!ok) return;

    isReady.value = true;
    _startTimer();
  }

  Future<bool> _fetchAndSubmit() async {
    final isSubmitted = await ErrorWrapper.async<bool>(
      () async {
        final newPos = await Geolocator.getCurrentPosition(
          locationSettings: _kLocationSettings,
        );
        if (position.value?.isSameAs(newPos) ?? false) return true;
        position.value = newPos;
        await _submitToSupabase(newPos);
        return true;
      },
      onError: (_) {
        if (position.value == null) {
          error.value = 'Unable to determine your location.';
        }
        return false;
      },
      library: _library,
      description: 'while fetching user location',
    );
    return isSubmitted!;
  }

  Future<void> _submitToSupabase(Position pos) async {
    await ErrorWrapper.async(
      () async {
        await _supabase.rpc(
          'update_scout_location',
          params: {'lat': pos.latitude, 'lng': pos.longitude},
        );
      },
      library: _library,
      description: 'while updating user location',
    );
  }

  void _startTimer() {
    _stopTimer();
    _periodicTimer =
        Timer.periodic(_kUpdateInterval, (_) => _fetchAndSubmit());
  }

  void _stopTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }
}
