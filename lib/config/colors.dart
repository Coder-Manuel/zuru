import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/services/theme_service/theme_service.dart';

/// Role-aware color accessor.
///
/// Every getter delegates to [ScoutColors] when the active role is scout,
/// otherwise to [ClientColors]. Only those two files ever need editing;
/// AppColors is purely a routing layer.
///
/// Usage is unchanged from before — `AppColors.primary` just works, and
/// automatically returns the right color for whichever role is active.
class AppColors {
  static bool get _isScout =>
      Get.isRegistered<ThemeService>() && ThemeService.to.isScout;

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static Color get background =>
      _isScout ? ScoutColors.background : ClientColors.background;
  static Color get surface =>
      _isScout ? ScoutColors.surface : ClientColors.surface;
  static Color get inputBg =>
      _isScout ? ScoutColors.inputBg : ClientColors.inputBg;
  // Scout-only token — only scout pages reference this.
  static Color get biometricBg => ScoutColors.biometricBg;

  // ── Primary Accent ────────────────────────────────────────────────────────
  static Color get primary =>
      _isScout ? ScoutColors.primary : ClientColors.primary;
  static Color get primaryDark =>
      _isScout ? ScoutColors.primaryDark : ClientColors.primaryDark;
  static Color get primaryGlow =>
      _isScout ? ScoutColors.primaryGlow : ClientColors.primaryGlow;

  // ── Text ──────────────────────────────────────────────────────────────────
  static Color get textPrimary =>
      _isScout ? ScoutColors.textPrimary : ClientColors.textPrimary;
  static Color get textSecondary =>
      _isScout ? ScoutColors.textSecondary : ClientColors.textSecondary;
  static Color get textAccent =>
      _isScout ? ScoutColors.textAccent : ClientColors.textAccent;

  // ── Chrome ────────────────────────────────────────────────────────────────
  static Color get divider =>
      _isScout ? ScoutColors.divider : ClientColors.divider;
  static Color get iconColor =>
      _isScout ? ScoutColors.iconColor : ClientColors.iconColor;
  // Scout-only token.
  static Color get otpBoxBg => ScoutColors.otpBoxBg;

  // ── Markers ───────────────────────────────────────────────────────────────
  static Color get scoutMarker =>
      _isScout ? ScoutColors.scoutMarker : ClientColors.scoutMarker;
  // Scout-only token.
  static Color get missionMarker => ScoutColors.missionMarker;

  // ── Map Grid (scout-only) ─────────────────────────────────────────────────
  static Color get mapGrid => ScoutColors.mapGrid;

  // ── Google / OAuth ────────────────────────────────────────────────────────
  static Color get googleBg => Colors.white;
  static Color get googleText => const Color(0xFF1F2937);
}

extension ColorExt on Color {
  Color setOpacity(double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return withAlpha((255.0 * opacity).round());
  }
}
