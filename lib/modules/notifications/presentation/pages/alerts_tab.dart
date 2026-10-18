import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/modules/notifications/presentation/controllers/notifications_controller.dart';
import 'package:zuru/modules/notifications/presentation/widgets/notification_list.dart';

/// Scout home → Alerts tab.
class AlertsTab extends GetView<NotificationsController> {
  const AlertsTab({super.key});

  @override
  Widget build(BuildContext context) {
    const palette = NotificationPalette.scout;
    return Scaffold(
      backgroundColor: ScoutColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => NotificationHeader(
                title: 'Alerts',
                hasUnread: controller.hasUnread,
                onMarkAllRead: controller.markAllRead,
                palette: palette,
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
                      'You\'re all caught up.\nNew requests will show up here.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
