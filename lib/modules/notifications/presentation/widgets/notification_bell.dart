import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/core/routes/app_routes.dart';
import 'package:zuru/modules/notifications/presentation/controllers/notifications_controller.dart';

/// Round bell with the unread count; opens the client notifications page.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<NotificationsController>()
        ? Get.find<NotificationsController>()
        : null;
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.notifications),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: ClientColors.inputBg,
          shape: BoxShape.circle,
          border: Border.all(color: ClientColors.divider),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: ClientColors.textPrimary,
              size: 22,
            ),
            if (controller != null)
              Obx(() {
                final count = controller.unreadCount;
                if (count == 0) return const SizedBox.shrink();
                return Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ClientColors.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
