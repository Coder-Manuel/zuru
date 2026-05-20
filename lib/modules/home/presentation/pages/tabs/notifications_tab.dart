import 'package:flutter/material.dart';
import 'package:zuru/config/colors.dart';

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Mark all read',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _notifications.length,
                itemBuilder: (_, i) {
                  final group = _notifications[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.date,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...group.items.map((n) => _NotificationItem(item: n)),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final _NotificationData item;
  const _NotificationItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.unread ? AppColors.surface : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: item.unread
            ? Border.all(color: AppColors.divider, width: 0.5)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight:
                        item.unread ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                item.time,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
              if (item.unread) ...[
                const SizedBox(height: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationGroup {
  final String date;
  final List<_NotificationData> items;
  const _NotificationGroup({required this.date, required this.items});
}

class _NotificationData {
  final String title;
  final String body;
  final String time;
  final bool unread;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _NotificationData({
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}

final _notifications = [
  _NotificationGroup(
    date: 'TODAY',
    items: [
      _NotificationData(
        title: 'Mission Assigned',
        body: 'You have been assigned to "Surveillance — Downtown".',
        time: '2h ago',
        unread: true,
        icon: Icons.my_location,
        iconBg: Color(0xFF1E3A2A),
        iconColor: Color(0xFF22C55E),
      ),
      _NotificationData(
        title: 'New Message',
        body: 'Your handler sent you a secure message.',
        time: '4h ago',
        unread: true,
        icon: Icons.message_outlined,
        iconBg: Color(0xFF1A2535),
        iconColor: AppColors.primary,
      ),
    ],
  ),
  _NotificationGroup(
    date: 'YESTERDAY',
    items: [
      _NotificationData(
        title: 'Mission Completed',
        body: '"Perimeter Check" marked as completed.',
        time: '1d ago',
        unread: false,
        icon: Icons.check_circle_outline,
        iconBg: Color(0xFF1E3A2A),
        iconColor: Color(0xFF22C55E),
      ),
      _NotificationData(
        title: 'Profile Updated',
        body: 'Your profile information was updated successfully.',
        time: '1d ago',
        unread: false,
        icon: Icons.person_outline,
        iconBg: Color(0xFF1A2535),
        iconColor: AppColors.textSecondary,
      ),
    ],
  ),
];
