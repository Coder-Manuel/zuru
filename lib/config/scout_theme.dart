import 'package:flutter/material.dart';
import 'package:zuru/config/scout_colors.dart';

class ScoutTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ScoutColors.background,
    primaryColor: ScoutColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: ScoutColors.primary,
      surface: ScoutColors.surface,
      onPrimary: Colors.black,
      onSurface: ScoutColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: ScoutColors.background,
      elevation: 0,
      iconTheme: IconThemeData(color: ScoutColors.textPrimary),
      titleTextStyle: TextStyle(
        color: ScoutColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: ScoutColors.textPrimary),
      bodyMedium: TextStyle(color: ScoutColors.textSecondary),
      titleLarge: TextStyle(
        color: ScoutColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ScoutColors.inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ScoutColors.primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: ScoutColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ScoutColors.primary,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        minimumSize: const Size(double.infinity, 55),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ScoutColors.primary,
        side: const BorderSide(color: ScoutColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        minimumSize: const Size(double.infinity, 55),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: ScoutColors.divider,
      thickness: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ScoutColors.surface,
      selectedItemColor: ScoutColors.primary,
      unselectedItemColor: ScoutColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      elevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: ScoutColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 0,
    ),
  );
}
