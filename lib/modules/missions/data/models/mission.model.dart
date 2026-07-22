import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:zuru/core/models/profile.model.dart';
import 'package:zuru/core/utils/ewkb_parser.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/data/models/session.model.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';
import 'package:zuru/modules/missions/domain/entities/session.entity.dart';
import 'package:zuru/modules/rating/data/models/rating.model.dart';
import 'package:zuru/modules/rating/domain/entities/rating.entity.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

class MissionModel extends MissionEntity {
  MissionModel({
    super.id,
    super.createdAt,
    super.updatedAt,
    super.clientId,
    super.scoutId,
    super.scout,
    super.client,
    super.sessionId,
    required super.description,
    required super.currency,
    required super.price,
    required super.durationInSec,
    required super.address,
    super.latitude,
    super.longitude,
    super.status,
    super.type,
    super.scheduledAt,
    super.mapX,
    super.mapY,
    super.acceptedAt,
    super.completedAt,
    super.publishedAt,
    super.ratings,
    super.recordingSession,
  });

  /// Parses the embedded `session` relationship, which Supabase returns as a
  /// single object (1:1) or a list (1:many). When it's a list we prefer the
  /// session that actually carries a recording, else the most recent one.
  static SessionEntity? _parseSession(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      return SessionModel.fromMap(Map<String, dynamic>.from(raw));
    }
    if (raw is List) {
      final sessions = raw
          .whereType<Map>()
          .map((e) => SessionModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      if (sessions.isEmpty) return null;
      sessions.sort((a, b) {
        final da = DateTime.tryParse(a.endedAt ?? a.createdAt ?? '') ?? DateTime(0);
        final db = DateTime.tryParse(b.endedAt ?? b.createdAt ?? '') ?? DateTime(0);
        return db.compareTo(da);
      });
      return sessions.firstWhere(
        (s) => (s.recordingUrl?.isNotEmpty ?? false),
        orElse: () => sessions.first,
      );
    }
    return null;
  }

  /// Parses a Supabase row from the **client** perspective (no mapX/mapY needed).
  factory MissionModel.fromMap(Map<String, dynamic> m) {
    final (:latitude, :longitude) = EwkbParser.parsePoint(
      m['location']?.toString(),
    );

    return MissionModel(
      id: m['id']?.toString(),
      createdAt: m['created_at']?.toString(),
      updatedAt: m['updated_at']?.toString(),
      clientId: m['client_id']?.toString(),
      scoutId: m['scout_id']?.toString(),
      sessionId: m['session_id']?.toString(),
      description: m['description']?.toString() ?? '',
      currency: m['currency']?.toString() ?? 'KES',
      price: (m['price'] as num?)?.toDouble() ?? 0,
      durationInSec: (m['duration_in_sec'] as int?) ?? 0,
      address: m['address']?.toString() ?? '',
      latitude: latitude,
      longitude: longitude,
      scout: m['scout'] != null ? ProfileModel.fromMap(m['scout']) : null,
      status: MissionStatus.values.firstWhere(
        (v) => v.name == m['status'],
        orElse: () => MissionStatus.open,
      ),
      type: m['type'] != null
          ? MissionType.values.firstWhere(
              (v) => v.apiValue == m['type'],
              orElse: () => MissionType.surveillance,
            )
          : null,
      scheduledAt: m['scheduled_at']?.toString(),
      ratings:
          m['ratings']
              ?.map<RatingEntity>((data) => RatingModel.fromMap(data))
              .toList() ??
          [],
      acceptedAt: m['accepted_at']?.toString(),
      completedAt: m['completed_at']?.toString(),
      publishedAt: m['published_at']?.toString(),
      recordingSession: _parseSession(m['session']),
    );
  }

  /// Parses a Supabase row from the **scout** perspective.
  /// Computes [mapX]/[mapY] canvas offsets from the scout's current GPS position.
  factory MissionModel.fromScoutMap(
    Map<String, dynamic> map, {
    double scoutLat = 0,
    double scoutLng = 0,
  }) {
    final (:latitude, :longitude) = EwkbParser.parsePoint(
      map['location']?.toString(),
    );

    const scoutMapX = 0.15;
    const scoutMapY = 0.12;
    const mapTotalKm = 4.0;

    const kmPerDegLat = 111.0;
    final kmPerDegLng = 111.0 * math.cos(scoutLat * math.pi / 180);

    final lat = latitude ?? 0;
    final lng = longitude ?? 0;

    final deltaLngKm = (lat - scoutLng) * kmPerDegLng;
    final deltaLatKm = (lng - scoutLat) * kmPerDegLat;

    final mapX = (scoutMapX + deltaLngKm / mapTotalKm).clamp(0.03, 0.95);
    final mapY = (scoutMapY - deltaLatKm / mapTotalKm).clamp(0.03, 0.95);

    return MissionModel(
      id: map['id'] as String?,
      clientId: map['client_id'] as String?,
      scoutId: map['scout_id'] as String?,
      type: map['type'] != null
          ? MissionType.values.firstWhere(
              (v) => v.apiValue == map['type'],
              orElse: () => MissionType.surveillance,
            )
          : null,
      client: map['client'] != null
          ? ProfileModel.fromMap(map['client'])
          : null,
      description: map['description'] as String? ?? '',
      currency: map['currency'] as String? ?? 'KES',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      durationInSec: (map['duration_in_sec'] as num?)?.toInt() ?? 0,
      address: map['address'] as String? ?? '',
      latitude: lat,
      longitude: lng,
      mapX: mapX,
      mapY: mapY,
      status: MissionStatus.values.firstWhere(
        (v) => v.name == map['status'],
        orElse: () => MissionStatus.open,
      ),
      scheduledAt: map['scheduled_at'] as String?,
      ratings:
          map['ratings']
              ?.map<RatingEntity>((data) => RatingModel.fromMap(data))
              .toList() ??
          [],
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      acceptedAt: map['accepted_at'] as String?,
      completedAt: map['completed_at'] as String?,
      publishedAt: map['published_at'] as String?,
    );
  }

  @override
  bool get isMyMission {
    return client?.userId == Get.find<UserController>().currentUser.value?.id;
  }
}
