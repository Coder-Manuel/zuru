import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/services/role_service/role_service.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/auth/presentation/controllers/login_controller.dart';
import 'package:zuru/modules/auth/presentation/pages/forgot_password_page.dart';
import 'package:zuru/modules/auth/presentation/pages/signup_page.dart';
import 'package:zuru/modules/auth/presentation/widgets/auth_widgets.dart';

class LoginPage extends GetView<LoginController> {
  static const String route = '/login';

  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final scheme = Theme.of(context).colorScheme;
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color;
    final iconColor = Theme.of(context).inputDecorationTheme.hintStyle?.color;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                50.verticalSpace,

                // ── App name ──────────────────────────────────────────────────
                Text(
                  'Zuru',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                8.verticalSpace,
                Text(
                  'See anywhere. Know everything.',
                  style: TextStyle(color: bodyColor, fontSize: 15),
                ),

                32.verticalSpace,

                // ── Role tab switcher ─────────────────────────────────────────
                const _RoleTabSwitcher(),

                40.verticalSpace,

                // ── Email ─────────────────────────────────────────────────────
                AuthTextField(
                  controller: controller.emailCTRL,
                  hint: 'Email address',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icon(
                    Icons.mail_outline,
                    color: iconColor,
                    size: 20,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your email';
                    if (!v.isEmail) return 'Enter valid email';
                    return null;
                  },
                ),

                16.verticalSpace,

                // ── Password ──────────────────────────────────────────────────
                Obx(
                  () => AuthTextField(
                    controller: controller.passwordCTRL,
                    hint: 'Password',
                    obscureText: controller.obscurePass.value,
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: iconColor,
                      size: 20,
                    ),
                    suffixIcon: GestureDetector(
                      onTap: controller.toggleObscurePass,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Icon(
                          controller.obscurePass.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter your password';
                      return null;
                    },
                  ),
                ),

                12.verticalSpace,

                // ── Forgot password ───────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Get.toNamed(ForgotPasswordPage.route),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                38.verticalSpace,

                // ── Login button + optional biometric ─────────────────────────
                Obx(() {
                  final isScout = RoleService.instance.isScout;
                  final bioBg = isScout
                      ? ScoutColors.biometricBg
                      : ClientColors.biometricBg;

                  return Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Login',
                          onPressed: () async =>
                              await controller.login(formKey),
                        ),
                      ),
                      if (controller.canLoginWithBiometrics.value) ...[
                        15.horizontalSpace,
                        GestureDetector(
                          onTap: controller.biometricLogin,
                          child: Container(
                            width: 65,
                            height: 55,
                            decoration: BoxDecoration(
                              color: bioBg,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              Icons.fingerprint,
                              color: scheme.primary,
                              size: 36,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                }),

                40.verticalSpace,
                const AuthDivider(),
                40.verticalSpace,

                // ── OAuth ─────────────────────────────────────────────────────
                GoogleButton(
                  label:
                      'Continue with ${GetPlatform.isIOS ? 'Apple' : 'Google'}',
                  onPressed: () async => await controller.oathLogin(),
                ),

                30.verticalSpace,

                // ── Sign up link ──────────────────────────────────────────────
                GestureDetector(
                  onTap: () => Get.offNamed(SignupPage.route),
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: bodyColor, fontSize: 15),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                10.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Role tab switcher ──────────────────────────────────────────────────────────

class _RoleTabSwitcher extends StatelessWidget {
  const _RoleTabSwitcher();

  @override
  Widget build(BuildContext context) {
    // fillColor from the current inputDecorationTheme gives us a surface shade
    // that's already calibrated for each role's background.
    final containerBg =
        Theme.of(context).inputDecorationTheme.fillColor ?? Colors.transparent;

    return Obx(() {
      final borderColor = Get.theme.primaryColor.withAlpha(60);

      return Container(
        height: 52,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RoleTab(
              label: 'Viewer',
              icon: Icons.person_outline_rounded,
              isSelected: !RoleService.instance.isScout,
              activeColor: Get.theme.primaryColor,
              onTap: () => RoleService.instance.applyClientTheme(),
            ),
            const SizedBox(width: 4),
            _RoleTab(
              label: 'Guide',
              icon: Icons.radar_rounded,
              isSelected: RoleService.instance.isScout,
              activeColor: Get.theme.primaryColor,
              onTap: () => RoleService.instance.applyScoutTheme(),
            ),
          ],
        ),
      );
    });
  }
}

class _RoleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _RoleTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.black : inactiveColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : inactiveColor,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
