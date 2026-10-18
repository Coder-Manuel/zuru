import 'package:flutter/material.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/utils/extensions.dart';
import 'package:zuru/modules/notifications/data/models/notification_type.dart';
import 'package:zuru/modules/notifications/domain/entities/app_notification.entity.dart';

/// Colours for the list, so the scout and client themes share one widget.
class NotificationPalette {
  final Color background;
  final Color surface;
  final Color divider;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;

  const NotificationPalette({
    required this.background,
    required this.surface,
    required this.divider,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
  });

  static const scout = NotificationPalette(
    background: ScoutColors.background,
    surface: ScoutColors.surface,
    divider: ScoutColors.divider,
    primary: ScoutColors.primary,
    textPrimary: ScoutColors.textPrimary,
    textSecondary: ScoutColors.textSecondary,
  );

  static const client = NotificationPalette(
    background: ClientColors.background,
    surface: ClientColors.inputBg,
    divider: ClientColors.divider,
    primary: ClientColors.primary,
    textPrimary: ClientColors.textPrimary,
    textSecondary: ClientColors.textSecondary,
  );
}

const _negative = Color(0xFFEF4444);
const _positive = Color(0xFF22C55E);

extension on NotificationType? {
  IconData get icon => switch (this) {
    NotificationType.liveRequestCreated => Icons.podcasts_rounded,
    NotificationType.missionRequestPaid => Icons.payments_outlined,
    NotificationType.requestCancelled => Icons.event_busy_outlined,
    NotificationType.missionAccepted => Icons.check_circle_outline,
    NotificationType.missionEnroute => Icons.directions_walk_rounded,
    NotificationType.scoutLive => Icons.videocam_outlined,
    NotificationType.missionDeclined => Icons.cancel_outlined,
    NotificationType.missionReleased => Icons.person_off_outlined,
    NotificationType.paymentExpired => Icons.timer_off_outlined,
    null => Icons.notifications_none_rounded,
  };

  Color accent(NotificationPalette palette) => switch (this) {
    NotificationType.missionRequestPaid => _positive,
    NotificationType.requestCancelled ||
    NotificationType.missionDeclined ||
    NotificationType.missionReleased ||
    NotificationType.paymentExpired => _negative,
    _ => palette.primary,
  };
}

class NotificationList extends StatelessWidget {
  final List<AppNotification> items;
  final bool Function(AppNotification) isRead;
  final ValueChanged<AppNotification> onTap;
  final NotificationPalette palette;
  final String emptyMessage;

  const NotificationList({
    super.key,
    required this.items,
    required this.isRead,
    required this.onTap,
    required this.palette,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(palette: palette, message: emptyMessage);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _NotificationCard(
        notification: items[i],
        read: isRead(items[i]),
        palette: palette,
        onTap: () => onTap(items[i]),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final bool read;
  final NotificationPalette palette;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.read,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = notification.createdAt != null
        ? DateTime.tryParse(notification.createdAt!)
        : null;
    final accent = notification.type.accent(palette);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface.setOpacity(read ? 0.5 : 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: read ? palette.divider.withAlpha(40) : accent.withAlpha(70),
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(notification.type.icon, color: accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!read)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    createdAt.timeAgo,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final NotificationPalette palette;
  final String message;

  const _EmptyState({required this.palette, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: palette.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: palette.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Title row with "Mark all read" while anything is unread.
class NotificationHeader extends StatelessWidget {
  final String title;
  final bool hasUnread;
  final VoidCallback onMarkAllRead;
  final NotificationPalette palette;
  final Widget? leading;

  const NotificationHeader({
    super.key,
    required this.title,
    required this.hasUnread,
    required this.onMarkAllRead,
    required this.palette,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (hasUnread)
            GestureDetector(
              onTap: onMarkAllRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
