import 'package:flutter/material.dart';
import 'package:zuru/config/client_colors.dart';

class ClientTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ClientColors.background,
    primaryColor: ClientColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: ClientColors.primary,
      surface: ClientColors.surface,
      onPrimary: Colors.white,
      onSurface: ClientColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: ClientColors.background,
      elevation: 0,
      iconTheme: IconThemeData(color: ClientColors.textPrimary),
      titleTextStyle: TextStyle(
        color: ClientColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: ClientColors.textPrimary),
      bodyMedium: TextStyle(color: ClientColors.textSecondary),
      titleLarge: TextStyle(
        color: ClientColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ClientColors.inputBg,
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
        borderSide: const BorderSide(color: ClientColors.primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: ClientColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ClientColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        minimumSize: const Size(double.infinity, 55),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ClientColors.primary,
        side: const BorderSide(color: ClientColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        minimumSize: const Size(double.infinity, 55),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: ClientColors.divider,
      thickness: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ClientColors.surface,
      selectedItemColor: ClientColors.primary,
      unselectedItemColor: ClientColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      elevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: ClientColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 0,
    ),
  );
}
