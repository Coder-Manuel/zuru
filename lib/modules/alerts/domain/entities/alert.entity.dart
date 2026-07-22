import 'package:flutter/material.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/entities/base.entity.dart';

/// Kinds of scout-facing alerts.
///
/// MVP ships a single kind — a client live-session request landing on the
/// scout. New kinds (mission accepted elsewhere, payout, rating received, …)
/// slot in here without touching the UI.
enum AlertType {
  liveRequestCreated;

  String get storageValue => switch (this) {
    AlertType.liveRequestCreated => 'live_request_created',
  };

  IconData get icon => switch (this) {
    AlertType.liveRequestCreated => Icons.podcasts_rounded,
  };

  Color get accent => switch (this) {
    AlertType.liveRequestCreated => ScoutColors.primary,
  };

  static AlertType fromStorage(String? value) => AlertType.values.firstWhere(
    (t) => t.storageValue == value,
    orElse: () => AlertType.liveRequestCreated,
  );
}

/// A single entry in the scout's alerts feed.
abstract class AlertEntity extends BaseEntity {
  final AlertType type;
  final String title;
  final String body;

  /// Mission this alert originated from, when applicable — used to deep-link
  /// into the mission details screen.
  final String? missionId;

  final bool isRead;

  AlertEntity({
    super.id,
    super.createdAt,
    required this.type,
    required this.title,
    required this.body,
    this.missionId,
    this.isRead = false,
  });
}
