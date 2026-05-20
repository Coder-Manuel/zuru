import 'package:flutter/material.dart';

/// Color palette for the **Client** role.
///
/// Edit these values freely — they only affect client-facing pages.
class ClientColors {
  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFF050A14);
  static const Color surface = Color(0xFF0C1628);
  static const Color inputBg = Color(0xFF111F35);

  // ── Primary Accent ────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF4D9EFF);
  static const Color primaryDark = Color(0xFF1A6FE0);
  static const Color primaryGlow = Color(0x334D9EFF);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF6B7A9A);
  static const Color textAccent = Color(0xFF4D9EFF);

  // ── Chrome ────────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFF1A2540);
  static const Color iconColor = Color(0xFF6B7A9A);

  // ── Map / Scouts marker ───────────────────────────────────────────────────
  static const Color scoutMarker = Color(0xFF4D9EFF);

  // ── Google / OAuth ────────────────────────────────────────────────────────
  static const Color googleBg = Colors.white;
  static const Color googleText = Color(0xFF1F2937);
}

extension ClientColorExt on Color {
  Color setOpacity(double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return withAlpha((255.0 * opacity).round());
  }
}
