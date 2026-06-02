import 'package:flutter/material.dart';

/// Colors shared across both roles — identical values in ClientColors and ScoutColors.
///
/// Role-specific colors live in ClientColors and ScoutColors respectively.
/// Pages import the color class for their role directly.
class AppColors {
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color googleBg = Colors.white;
  static const Color googleText = Color(0xFF1F2937);
}
