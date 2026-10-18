import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/core/routes/app_routes.dart';
import 'package:zuru/modules/notifications/presentation/controllers/notifications_controller.dart';
import 'package:zuru/modules/notifications/presentation/widgets/notification_list.dart';

/// Client notifications, opened from the bell on the Map and Live Checks tabs.
class NotificationsPage extends GetView<NotificationsController> {
  static const String route = AppRoutes.notifications;

  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const palette = NotificationPalette.client;
    return Scaffold(
      backgroundColor: ClientColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => NotificationHeader(
                title: 'Notifications',
                hasUnread: controller.hasUnread,
                onMarkAllRead: controller.markAllRead,
                palette: palette,
                leading: GestureDetector(
                  onTap: Get.back,
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: ClientColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(
                () => NotificationList(
                  items: controller.notifications.toList(),
                  isRead: controller.isRead,
                  onTap: controller.onTap,
                  palette: palette,
                  emptyMessage:
                      'You\'re all caught up.\nUpdates on your live checks will show up here.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
