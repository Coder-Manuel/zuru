import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/routes/app_routes.dart';
import 'package:zuru/core/services/role_service/role_service.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/core/widgets/app_cached_image.dart';
import 'package:zuru/modules/payments/presentation/pages/statements_page.dart';
import 'package:zuru/modules/user/presentation/controllers/profile_controller.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

class ProfilePage extends GetView<ProfileController> {
  static const String route = '/scout/profile';
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color;
    final fillColor = Theme.of(context).inputDecorationTheme.fillColor;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              32.verticalSpace,

              // ── Avatar + name ────────────────────────────────────────────────
              _ProfileHeader(
                    controller: controller,
                    scheme: scheme,
                    bodyColor: bodyColor,
                  )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.08, end: 0, duration: 500.ms),

              40.verticalSpace,

              // ── Settings rows ────────────────────────────────────────────────
              _ToggleRow(
                    icon: Icons.fingerprint_rounded,
                    title: 'Enable Biometrics',
                    subtitle: 'Face ID or Fingerprint',
                    valueObs: controller.biometricsEnabled,
                    onChanged: controller.toggleBiometrics,
                    scheme: scheme,
                    bodyColor: bodyColor,
                    fillColor: fillColor,
                  )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 500.ms)
                  .slideY(begin: 0.08, end: 0, delay: 80.ms, duration: 500.ms),

              8.verticalSpace,

              _ToggleRow(
                    icon: Icons.notifications_outlined,
                    title: 'Push Notifications',
                    subtitle: 'Mission alerts & updates',
                    valueObs: controller.notificationsEnabled,
                    onChanged: controller.toggleNotifications,
                    scheme: scheme,
                    bodyColor: bodyColor,
                    fillColor: fillColor,
                  )
                  .animate()
                  .fadeIn(delay: 160.ms, duration: 500.ms)
                  .slideY(begin: 0.08, end: 0, delay: 160.ms, duration: 500.ms),

              8.verticalSpace,

              _NavRow(
                    icon: Icons.credit_card_outlined,
                    title: 'Payment Statements',
                    onTap: () => Get.toNamed(StatementsPage.route),
                    scheme: scheme,
                    bodyColor: bodyColor,
                    fillColor: fillColor,
                  )
                  .animate()
                  .fadeIn(delay: 240.ms, duration: 500.ms)
                  .slideY(begin: 0.08, end: 0, delay: 240.ms, duration: 500.ms),

              8.verticalSpace,

              _LinkRow(
                    icon: Icons.shield_outlined,
                    title: 'Privacy Policy',
                    url: 'https://unseenapp.com/privacy',
                    scheme: scheme,
                    bodyColor: bodyColor,
                    fillColor: fillColor,
                  )
                  .animate()
                  .fadeIn(delay: 320.ms, duration: 500.ms)
                  .slideY(begin: 0.08, end: 0, delay: 320.ms, duration: 500.ms),

              8.verticalSpace,

              _LinkRow(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    url: 'https://unseenapp.com/terms',
                    scheme: scheme,
                    bodyColor: bodyColor,
                    fillColor: fillColor,
                  )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 500.ms)
                  .slideY(begin: 0.08, end: 0, delay: 400.ms, duration: 500.ms),

              24.verticalSpace,

              // ── Switch Role ──────────────────────────────────────────────────
              _RoleSwitchCard(
                    userController: Get.find<UserController>(),
                    bodyColor: bodyColor,
                    fillColor: fillColor,
                  )
                  .animate()
                  .fadeIn(delay: 480.ms, duration: 500.ms)
                  .slideY(begin: 0.08, end: 0, delay: 480.ms, duration: 500.ms),

              32.verticalSpace,

              // ── Logout ───────────────────────────────────────────────────────
              Obx(
                    () => _LogoutButton(
                      isLoading: controller.isLoggingOut.value,
                      onTap: controller.logout,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 560.ms, duration: 500.ms)
                  .slideY(begin: 0.08, end: 0, delay: 560.ms, duration: 500.ms),

              28.verticalSpace,

              Text(
                'ZURU WORLD  v1.0.4',
                style: TextStyle(
                  color: bodyColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                ),
              ).animate().fadeIn(delay: 640.ms, duration: 500.ms),

              24.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Role switch card ──────────────────────────────────────────────────────────

class _RoleSwitchCard extends StatelessWidget {
  final UserController userController;
  final Color? bodyColor;
  final Color? fillColor;

  const _RoleSwitchCard({
    required this.userController,
    required this.bodyColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isScout = RoleService.instance.isScout;
      final targetLabel = isScout ? 'Client' : 'Scout';
      final targetIcon = isScout
          ? Icons.person_outline_rounded
          : Icons.radar_rounded;
      final targetColor = isScout ? ClientColors.primary : ScoutColors.primary;

      return GestureDetector(
        onTap: userController.isSwitchingRole.value
            ? null
            : () => _showConfirmSheet(
                context: context,
                isCurrentlyScout: isScout,
                targetLabel: targetLabel,
                targetIcon: targetIcon,
                targetColor: targetColor,
              ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: targetColor.withAlpha(15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: targetColor.withAlpha(60), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: targetColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(targetIcon, color: targetColor, size: 22),
              ),
              14.horizontalSpace,
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
                    4.verticalSpace,
                    Text(
                      isScout
                          ? 'Post missions & watch live feeds'
                          : 'Accept missions & stream live',
                      style: TextStyle(color: bodyColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              userController.isSwitchingRole.value
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
    required bool isCurrentlyScout,
    required String targetLabel,
    required IconData targetIcon,
    required Color targetColor,
  }) {
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: bodyColor?.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            24.verticalSpace,
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: targetColor.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(targetIcon, color: targetColor, size: 34),
            ),
            20.verticalSpace,
            Text(
              'Switch to $targetLabel?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            10.verticalSpace,
            Text(
              isCurrentlyScout
                  ? 'You\'ll switch to Client mode — browse, post missions and watch scouts in the field.'
                  : 'You\'ll switch to Scout mode — accept missions, navigate to locations and stream live to clients.',
              textAlign: TextAlign.center,
              style: TextStyle(color: bodyColor, fontSize: 14, height: 1.5),
            ),
            28.verticalSpace,
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
                12.horizontalSpace,
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      userController.switchRole();
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
                    child: const Text(
                      'Switch',
                      style: TextStyle(fontWeight: FontWeight.w700),
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

// ── Profile header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final ProfileController controller;
  final ColorScheme scheme;
  final Color? bodyColor;

  const _ProfileHeader({
    required this.controller,
    required this.scheme,
    required this.bodyColor,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = Theme.of(context).inputDecorationTheme.fillColor;
    return Obx(() {
      final user = controller.currentUser.value;
      final profile = user?.profile;
      final name = profile?.fullName ?? '';
      final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
      final rating = profile?.rating?.toStringAsFixed(1) ?? '—';
      final locality = profile?.locality;
      final avatarUrl = profile?.avatarUrl;
      final isScout = RoleService.instance.isScout;

      return Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.primary, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withAlpha(50),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: AppCachedImage(
                    url: avatarUrl,
                    fallback: Container(
                      color: fillColor,
                      child: Center(
                        child: Text(
                          initial,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (isScout)
                Positioned(
                  right: -2,
                  bottom: 2,
                  child: GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.scoutProfileEdit),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 3),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          12.verticalSpace,
          Text(
            name.isNotEmpty ? name : 'Scout',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 25,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
          ),
          8.verticalSpace,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isScout ? 'Scout' : 'Client',
                style: TextStyle(color: bodyColor, fontSize: 13),
              ),
              Text(' · ', style: TextStyle(color: bodyColor, fontSize: 13)),
              Text(rating, style: TextStyle(color: bodyColor, fontSize: 13)),
              const SizedBox(width: 4),
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFD700),
                size: 16,
              ),
              if (locality != null && locality.isNotEmpty) ...[
                Text(' · ', style: TextStyle(color: bodyColor, fontSize: 13)),
                Text(
                  locality,
                  style: TextStyle(color: bodyColor, fontSize: 13),
                ),
              ],
            ],
          ),
          if (isScout) ...[
            12.verticalSpace,
            _EditProfileButton(
              scheme: scheme,
              onTap: () => Get.toNamed(AppRoutes.scoutProfileEdit),
            ),
          ],
        ],
      );
    });
  }
}

// ── Edit profile button ───────────────────────────────────────────────────────

class _EditProfileButton extends StatelessWidget {
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _EditProfileButton({required this.scheme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: scheme.primary.withAlpha(110)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, color: scheme.primary, size: 16),
            8.horizontalSpace,
            Text(
              'EDIT MY WORLD PROFILE',
              style: TextStyle(
                color: scheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Toggle row ────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final RxBool valueObs;
  final void Function(bool) onChanged;
  final ColorScheme scheme;
  final Color? bodyColor;
  final Color? fillColor;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.valueObs,
    required this.onChanged,
    required this.scheme,
    required this.bodyColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor?.withAlpha(178),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _IconBox(icon: icon, primaryColor: scheme.primary),
            14.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    subtitle,
                    style: TextStyle(color: bodyColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            Obx(
              () => Switch.adaptive(
                value: valueObs.value,
                onChanged: onChanged,
                activeThumbColor: Colors.black,
                activeTrackColor: scheme.primary,
                inactiveThumbColor: bodyColor,
                inactiveTrackColor: fillColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nav row ───────────────────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final Color? bodyColor;
  final Color? fillColor;

  const _NavRow({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.scheme,
    required this.bodyColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: fillColor?.withAlpha(178),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              _IconBox(icon: icon, primaryColor: scheme.primary),
              14.horizontalSpace,
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: bodyColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Link row ──────────────────────────────────────────────────────────────────

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String url;
  final ColorScheme scheme;
  final Color? bodyColor;
  final Color? fillColor;

  const _LinkRow({
    required this.icon,
    required this.title,
    required this.url,
    required this.scheme,
    required this.bodyColor,
    required this.fillColor,
  });

  Future<void> _launch() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launch,
      child: Container(
        decoration: BoxDecoration(
          color: fillColor?.withAlpha(178),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: bodyColor, size: 22),
              14.horizontalSpace,
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: scheme.onSurface, fontSize: 15),
                ),
              ),
              Icon(Icons.link_rounded, color: scheme.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Icon box ──────────────────────────────────────────────────────────────────

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color primaryColor;
  const _IconBox({required this.icon, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: primaryColor.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: primaryColor, size: 20),
    );
  }
}

// ── Logout button ─────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _LogoutButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withAlpha(25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEF4444).withAlpha(60)),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Color(0xFFEF4444),
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Logout',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
