import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/services/role_service/role_service.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

class SettingsTab extends GetView<UserController> {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color;
    final fillColor = Theme.of(context).inputDecorationTheme.fillColor;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 36),

            // ── Profile header ────────────────────────────────────────────────
            Obx(() {
              final user = controller.currentUser.value;
              final name = user?.profile?.fullName ?? 'User';
              final role = _roleLabel(user?.profile?.role?.name);
              final rating = user?.profile?.rating?.toStringAsFixed(1) ?? '–';

              return Column(
                children: [
                  _ProfileAvatar(name: name, primaryColor: scheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: TextStyle(
                      color: scheme.onSurface,
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
                        style: TextStyle(color: bodyColor, fontSize: 14),
                      ),
                      Text(
                        ' · ',
                        style: TextStyle(color: bodyColor, fontSize: 14),
                      ),
                      Text(
                        rating,
                        style: TextStyle(color: bodyColor, fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.star_rounded, color: bodyColor, size: 16),
                    ],
                  ),
                ],
              );
            }),

            const SizedBox(height: 36),

            // ── Settings tiles ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Biometrics
                  Obx(
                    () => _SettingsCard(
                      icon: Icons.fingerprint_rounded,
                      title: 'Enable Biometrics',
                      subtitle: 'Face ID or Fingerprint',
                      fillColor: fillColor,
                      primaryColor: scheme.primary,
                      textColor: scheme.onSurface,
                      subtitleColor: bodyColor,
                      trailing: _AppSwitch(
                        value: controller.biometricsEnabled.value,
                        activeColor: scheme.primary,
                        onChanged: (v) =>
                            controller.biometricsEnabled.value = v,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Notifications
                  Obx(
                    () => _SettingsCard(
                      icon: Icons.notifications_outlined,
                      title: 'Push Notifications',
                      subtitle: 'Live Check alerts & updates',
                      fillColor: fillColor,
                      primaryColor: scheme.primary,
                      textColor: scheme.onSurface,
                      subtitleColor: bodyColor,
                      trailing: _AppSwitch(
                        value: controller.notificationsEnabled.value,
                        activeColor: scheme.primary,
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
                    fillColor: fillColor,
                    primaryColor: scheme.primary,
                    textColor: scheme.onSurface,
                    subtitleColor: bodyColor,
                    trailing: Icon(
                      Icons.link_rounded,
                      color: scheme.primary,
                      size: 20,
                    ),
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),

                  // Terms & Conditions
                  _SettingsCard(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    fillColor: fillColor,
                    primaryColor: scheme.primary,
                    textColor: scheme.onSurface,
                    subtitleColor: bodyColor,
                    trailing: Icon(
                      Icons.link_rounded,
                      color: scheme.primary,
                      size: 20,
                    ),
                    onTap: () {},
                  ),

                  const SizedBox(height: 24),

                  // ── Switch Role ───────────────────────────────────────────
                  _RoleSwitchCard(
                    controller: controller,
                    fillColor: fillColor,
                    textColor: scheme.onSurface,
                    subtitleColor: bodyColor,
                  ),

                  const SizedBox(height: 28),

                  // Logout
                  _LogoutButton(onTap: () async => await controller.logout()),

                  const SizedBox(height: 24),

                  Text(
                    'ZURU WORLD  v1.0.4',
                    style: TextStyle(
                      color: bodyColor,
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

  static String _roleLabel(String? role) =>
      role?.toLowerCase() == 'scout' ? 'Guide' : 'Viewer';
}

// ── Role switch card ──────────────────────────────────────────────────────────

class _RoleSwitchCard extends StatelessWidget {
  final UserController controller;
  final Color? fillColor;
  final Color textColor;
  final Color? subtitleColor;

  const _RoleSwitchCard({
    required this.controller,
    required this.fillColor,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isScout = RoleService.instance.isScout;
      final targetLabel = isScout ? 'Viewer' : 'Guide';
      final targetIcon = isScout
          ? Icons.person_outline_rounded
          : Icons.radar_rounded;
      final targetColor = isScout ? ClientColors.primary : ScoutColors.primary;

      return GestureDetector(
        onTap: controller.isSwitchingRole.value
            ? null
            : () => _showConfirmSheet(
                context: context,
                controller: controller,
                isCurrentlyScout: isScout,
                targetLabel: targetLabel,
                targetIcon: targetIcon,
                targetColor: targetColor,
              ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: targetColor.withAlpha(15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: targetColor.withAlpha(60), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: targetColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(targetIcon, color: targetColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Switch to $targetLabel',
                      style: TextStyle(
                        color: targetColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isScout
                          ? 'Post live checks & watch live feeds'
                          : 'Accept live checks & stream live',
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              controller.isSwitchingRole.value
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: targetColor,
                      ),
                    )
                  : Icon(
                      Icons.swap_horiz_rounded,
                      color: targetColor,
                      size: 22,
                    ),
            ],
          ),
        ),
      );
    });
  }

  void _showConfirmSheet({
    required BuildContext context,
    required UserController controller,
    required bool isCurrentlyScout,
    required String targetLabel,
    required IconData targetIcon,
    required Color targetColor,
  }) {
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: bodyColor?.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Role icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: targetColor.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(targetIcon, color: targetColor, size: 34),
            ),
            const SizedBox(height: 20),

            Text(
              'Switch to $targetLabel?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isCurrentlyScout
                  ? 'You\'ll switch to Viewer mode — browse, post live checks and watch guides in the field.'
                  : 'You\'ll switch to Guide mode — accept live checks, navigate to locations and stream live to viewers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: bodyColor, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: Get.back,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: bodyColor,
                      side: BorderSide(
                        color: bodyColor?.withAlpha(60) ?? Colors.grey,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      controller.switchRole();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: targetColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Switch',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile avatar ────────────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final Color primaryColor;
  const _ProfileAvatar({required this.name, required this.primaryColor});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = Theme.of(context).inputDecorationTheme.fillColor;
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primaryColor, width: 3),
        color: fillColor,
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: primaryColor,
            fontSize: 34,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Settings card ─────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? fillColor;
  final Color primaryColor;
  final Color textColor;
  final Color? subtitleColor;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.primaryColor,
    required this.textColor,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.fillColor,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fillColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(color: subtitleColor, fontSize: 12),
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

// ── Toggle switch ─────────────────────────────────────────────────────────────

class _AppSwitch extends StatelessWidget {
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _AppSwitch({
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color;
    final fillColor = Theme.of(context).inputDecorationTheme.fillColor;
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: activeColor,
      activeTrackColor: fillColor,
      inactiveThumbColor: bodyColor,
      inactiveTrackColor: fillColor,
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );
  }
}

// ── Logout button ─────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: const Color(0xFFEF4444).withAlpha(25),
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
