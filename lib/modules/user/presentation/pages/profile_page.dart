import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zuru/config/colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/payments/presentation/pages/statements_page.dart';
import 'package:zuru/modules/user/presentation/controllers/profile_controller.dart';

class ProfilePage extends GetView<ProfileController> {
  static const String route = '/scout/profile';
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              32.verticalSpace,

              // ── Avatar + name ──────────────────────────────────────────────
              _ProfileHeader(controller: controller)
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOut,
                  ),

              40.verticalSpace,

              // ── Settings rows (each delayed by 80ms more than the last) ───
              _ToggleRow(
                    icon: Icons.fingerprint_rounded,
                    title: 'Enable Biometrics',
                    subtitle: 'Face ID or Fingerprint',
                    valueObs: controller.biometricsEnabled,
                    onChanged: controller.toggleBiometrics,
                  )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 500.ms)
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    delay: 80.ms,
                    duration: 500.ms,
                    curve: Curves.easeOut,
                  ),

              8.verticalSpace,

              _ToggleRow(
                    icon: Icons.notifications_outlined,
                    title: 'Push Notifications',
                    subtitle: 'Mission alerts & updates',
                    valueObs: controller.notificationsEnabled,
                    onChanged: controller.toggleNotifications,
                  )
                  .animate()
                  .fadeIn(delay: 160.ms, duration: 500.ms)
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    delay: 160.ms,
                    duration: 500.ms,
                    curve: Curves.easeOut,
                  ),

              8.verticalSpace,

              _NavRow(
                    icon: Icons.credit_card_outlined,
                    title: 'Payment Statements',
                    onTap: () => Get.toNamed(StatementsPage.route),
                  )
                  .animate()
                  .fadeIn(delay: 240.ms, duration: 500.ms)
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    delay: 240.ms,
                    duration: 500.ms,
                    curve: Curves.easeOut,
                  ),

              8.verticalSpace,

              _NavRow(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Payment Methods',
                    onTap: () {}, // stub
                  )
                  .animate()
                  .fadeIn(delay: 320.ms, duration: 500.ms)
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    delay: 320.ms,
                    duration: 500.ms,
                    curve: Curves.easeOut,
                  ),

              8.verticalSpace,

              _LinkRow(
                    icon: Icons.shield_outlined,
                    title: 'Privacy Policy',
                    url: 'https://unseenapp.com/privacy',
                  )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 500.ms)
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    delay: 400.ms,
                    duration: 500.ms,
                    curve: Curves.easeOut,
                  ),

              8.verticalSpace,

              _LinkRow(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    url: 'https://unseenapp.com/terms',
                  )
                  .animate()
                  .fadeIn(delay: 480.ms, duration: 500.ms)
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    delay: 480.ms,
                    duration: 500.ms,
                    curve: Curves.easeOut,
                  ),

              32.verticalSpace,

              // ── Logout ─────────────────────────────────────────────────────
              Obx(
                    () => _LogoutButton(
                      isLoading: controller.isLoggingOut.value,
                      onTap: controller.logout,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 560.ms, duration: 500.ms)
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    delay: 560.ms,
                    duration: 500.ms,
                    curve: Curves.easeOut,
                  ),

              28.verticalSpace,

              // ── Version ────────────────────────────────────────────────────
              const Text(
                'SCOUT APP V1.0.4',
                style: TextStyle(
                  color: AppColors.textSecondary,
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

// ── Profile header (avatar + name + rating) ───────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final ProfileController controller;
  const _ProfileHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.currentUser.value;
      final name = user?.fullName ?? '';
      final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
      final rating = user?.rating?.toStringAsFixed(1) ?? '—';

      return Column(
        children: [
          // ── Avatar ──────────────────────────────────────────────────────
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(50),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                color: AppColors.surface,
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),

          18.verticalSpace,

          // ── Name ────────────────────────────────────────────────────────
          Text(
            name.isNotEmpty ? name : 'Scout',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
          ),

          8.verticalSpace,

          // ── Role + rating ────────────────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scout',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const Text(
                ' · ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              Text(
                rating,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFD700),
                size: 16,
              ),
            ],
          ),
        ],
      );
    });
  }
}

// ── Toggle row (biometrics, notifications) ────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final RxBool valueObs;
  final void Function(bool) onChanged;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.valueObs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.setOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _IconBox(icon: icon),
            14.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Obx(
              () => Switch.adaptive(
                value: valueObs.value,
                onChanged: onChanged,
                activeThumbColor: AppColors.background,
                activeTrackColor: AppColors.primary,
                inactiveThumbColor: AppColors.textSecondary,
                inactiveTrackColor: AppColors.divider,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Navigation row (payment statements, payment methods) ──────────────────────

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _NavRow({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.setOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              _IconBox(icon: icon),
              14.horizontalSpace,
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Link row (privacy policy, terms) ─────────────────────────────────────────

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String url;

  const _LinkRow({required this.icon, required this.title, required this.url});

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
          color: AppColors.surface.setOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 22),
              14.horizontalSpace,
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
              const Icon(
                Icons.link_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Icon box (green-tinted background) ───────────────────────────────────────

class _IconBox extends StatelessWidget {
  final IconData icon;
  const _IconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primaryGlow.setOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
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
          color: const Color(0xFF2A1010),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCC1E1E).withAlpha(60)),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Color(0xFFCC1E1E),
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Logout',
                  style: TextStyle(
                    color: Color(0xFFCC1E1E),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
