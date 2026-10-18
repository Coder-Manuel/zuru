import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';

class Toast {
  static void _show(
    String message, {
    bool isError = false,
    Color? color,
    String? title,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
    VoidCallback? onTap,
  }) {
    if (Get.overlayContext == null) return;
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

    Get.snackbar(
      title ?? (isError ? 'Error' : 'Success'),
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: isError
          ? const Color(0xFF940000)
          : (color ?? ClientColors.primary),
      colorText: Colors.white,
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      borderRadius: 15,
      duration: duration,
      onTap: onTap == null
          ? null
          : (_) {
              Get.closeCurrentSnackbar();
              onTap();
            },
      icon: Icon(
        icon ??
            (isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline),
        color: Colors.white,
        size: 28,
      ),
      shouldIconPulse: false,
      snackStyle: SnackStyle.FLOATING,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    );
  }

  static void success(String message, {String? title}) =>
      _show(message, title: title ?? 'Success', color: Colors.green);

  static void error(String message, {String? title}) =>
      _show(message, title: title ?? 'Error', isError: true);

  static void info(String message, {String? title}) => _show(
    message,
    title: title ?? 'Info',
    color: const Color.fromARGB(255, 195, 147, 5),
  );

  /// An incoming notification while the app is open; tapping opens it.
  static void notify(String title, String message, {VoidCallback? onTap}) =>
      _show(
        message,
        title: title,
        color: ClientColors.primary,
        icon: Icons.notifications_active_outlined,
        duration: const Duration(seconds: 5),
        onTap: onTap,
      );

  static void warning(String message, {String? title}) =>
      _show(message, title: title ?? 'Warning', color: Colors.orange);
}
