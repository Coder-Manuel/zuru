import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/colors.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

class SettingsTab extends GetView<UserController> {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Profile header ──────────────────────────────────────────────
            const SizedBox(height: 36),
            Obx(() {
              final user = controller.currentUser.value;
              final name = user?.fullName ?? 'User';
              final role = _roleLabel(user?.role?.name);
              final rating = user?.rating?.toStringAsFixed(1) ?? '–';
              return Column(
                children: [
                  _ProfileAvatar(name: name),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        role,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        ' · ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        rating,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              );
            }),

            const SizedBox(height: 36),

            // ── Settings tiles ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Enable Biometrics
                  Obx(
                    () => _SettingsCard(
                      icon: Icons.fingerprint_rounded,
                      title: 'Enable Biometrics',
                      subtitle: 'Face ID or Fingerprint',
                      trailing: _AppSwitch(
                        value: controller.biometricsEnabled.value,
                        onChanged: (v) =>
                            controller.biometricsEnabled.value = v,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Push Notifications
                  Obx(
                    () => _SettingsCard(
                      icon: Icons.notifications_outlined,
                      title: 'Push Notifications',
                      subtitle: 'Mission alerts & updates',
                      trailing: _AppSwitch(
                        value: controller.notificationsEnabled.value,
                        onChanged: (v) =>
                            controller.notificationsEnabled.value = v,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Privacy Policy
                  _SettingsCard(
                    icon: Icons.shield_outlined,
                    title: 'Privacy Policy',
                    trailing: const Icon(
                      Icons.link_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),

                  // Terms & Conditions
                  _SettingsCard(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    trailing: const Icon(
                      Icons.link_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),

                  // Account Settings
                  _SettingsCard(
                    icon: Icons.settings_outlined,
                    title: 'Account Settings',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    onTap: () {},
                  ),

                  const SizedBox(height: 28),

                  // ── Logout ────────────────────────────────────────────────
                  _LogoutButton(onTap: () async => await controller.logout()),

                  const SizedBox(height: 24),

                  // ── Version ───────────────────────────────────────────────
                  const Text(
                    'UNSEEN APP VERSION 1.0.4',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _roleLabel(String? role) {
    switch (role?.toLowerCase()) {
      case 'scout':
        return 'Scout';
      case 'client':
      default:
        return 'Client';
    }
  }
}

// ─── Profile avatar ───────────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  final String name;
  const _ProfileAvatar({required this.name});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 3),
        color: AppColors.inputBg,
      ),
      child: Center(
        child: Text(
          _initials,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 34,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Settings card ────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Toggle switch ────────────────────────────────────────────────────────────

class _AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AppSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      activeTrackColor: const Color(0xFF3A3A3A),
      inactiveThumbColor: AppColors.textSecondary,
      inactiveTrackColor: const Color(0xFF2A2A2A),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );
  }
}

// ─── Logout button ────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: const Color(0xFF3B1219),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
