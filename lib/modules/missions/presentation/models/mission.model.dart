import 'dart:math';

import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';

class MissionModel {
  final String id;
  final String type;
  final int price;
  final String currency;
  final String location;
  final int distanceMeters;
  final int durationMinutes;
  final String instructions;
  final String clientName;
  final double clientRating;
  final int clientMissions;

  /// Fractional position on the radar canvas (0.0 – 1.0).
  final double mapX;
  final double mapY;

  const MissionModel({
    required this.id,
    required this.type,
    required this.price,
    required this.currency,
    required this.location,
    required this.distanceMeters,
    required this.durationMinutes,
    required this.instructions,
    required this.clientName,
    required this.clientRating,
    required this.clientMissions,
    required this.mapX,
    required this.mapY,
  });

  // ── Factory: build from domain entity ────────────────────────────────────────

  /// [scoutLat] / [scoutLng] — the scout's current GPS position.
  ///
  /// Radar coordinate system:
  ///   • Scout is fixed at (0.15, 0.12) on the map canvas (top-left area)
  ///     matching the UI design.
  ///   • The canvas represents a 4 km × 4 km area (±2 km from scout).
  ///   • 1 km = 0.25 of the canvas width / height.
  factory MissionModel.fromEntity(
    MissionEntity entity,
    double scoutLat,
    double scoutLng,
  ) {
    const scoutMapX = 0.15;
    const scoutMapY = 0.12;
    const mapTotalKm = 4.0; // canvas represents 4 km in each axis

    // Kilometre offsets from scout → mission
    const kmPerDegLat = 111.0;
    final kmPerDegLng = 111.0 * cos(scoutLat * pi / 180);

    final lat = entity.latitude ?? 0.0;
    final lng = entity.longitude ?? 0.0;

    final deltaLngKm = (lng - scoutLng) * kmPerDegLng;
    final deltaLatKm = (lat - scoutLat) * kmPerDegLat;

    // Screen Y is inverted relative to latitude
    final mapX = (scoutMapX + deltaLngKm / mapTotalKm).clamp(0.03, 0.95);
    final mapY = (scoutMapY - deltaLatKm / mapTotalKm).clamp(0.03, 0.95);

    final distM = _haversineMeters(scoutLat, scoutLng, lat, lng);

    return MissionModel(
      id: entity.id ?? '',
      type: entity.description,
      price: entity.price.toInt(),
      currency: entity.currency,
      location: entity.address,
      distanceMeters: distM.round(),
      durationMinutes: entity.durationInSec ~/ 60,
      instructions: entity.description,
      // Client details are not stored on the missions table yet; use defaults.
      clientName: 'Client',
      clientRating: 4.5,
      clientMissions: 0,
      mapX: mapX,
      mapY: mapY,
    );
  }

  // ── Computed display helpers ──────────────────────────────────────────────────

  String get formattedPrice => '$currency ${_fmt(price)}';
  String get formattedDistance => '${distanceMeters}m away';
  String get formattedDistanceLabel =>
      '${distanceMeters}M AWAY FROM YOUR LOCATION';

  static String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  // ── Haversine (metres) ────────────────────────────────────────────────────────
  static double _haversineMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371000.0;
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final dPhi = (lat2 - lat1) * pi / 180;
    final dLam = (lng2 - lng1) * pi / 180;
    final a = sin(dPhi / 2) * sin(dPhi / 2) +
        cos(phi1) * cos(phi2) * sin(dLam / 2) * sin(dLam / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
