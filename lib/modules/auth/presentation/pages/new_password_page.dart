import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/colors.dart';
import 'package:zuru/core/utils/extensions.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/auth/presentation/controllers/reset_password_controller.dart';
import 'package:zuru/modules/auth/presentation/widgets/auth_widgets.dart';

class NewPasswordPage extends GetView<ResetPasswordController> {
  static const String route = '/new-password';

  const NewPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                24.verticalSpace,

                // ── Back to login ───────────────────────────────────────────
                _BackToLoginButton(),

                60.verticalSpace,

                // ── Heading ─────────────────────────────────────────────────
                Text(
                  'New Password',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                14.verticalSpace,
                Text(
                  'Choose a strong password for your UnSeen account.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),

                40.verticalSpace,

                // ── New password field ───────────────────────────────────────
                Obx(
                  () => AuthTextField(
                    controller: controller.newPasswordCTRL,
                    hint: 'New Password',
                    obscureText: controller.obscureNewPass.value,
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.iconColor,
                      size: 20,
                    ),
                    suffixIcon: GestureDetector(
                      onTap: controller.toggleObscureNewPass,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Icon(
                          controller.obscureNewPass.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.iconColor,
                          size: 20,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter a new password';
                      if (v.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      if (!v.isStrongPassword) {
                        return 'Use uppercase, lowercase, digit & special char';
                      }
                      return null;
                    },
                  ),
                ),

                16.verticalSpace,

                // ── Confirm password field ───────────────────────────────────
                Obx(
                  () => AuthTextField(
                    controller: controller.confirmPasswordCTRL,
                    hint: 'Confirm New Password',
                    obscureText: controller.obscureConfirmPass.value,
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.iconColor,
                      size: 20,
                    ),
                    suffixIcon: GestureDetector(
                      onTap: controller.toggleObscureConfirmPass,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Icon(
                          controller.obscureConfirmPass.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.iconColor,
                          size: 20,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirm your password';
                      if (v != controller.newPasswordCTRL.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ),

                32.verticalSpace,

                // ── Submit button ────────────────────────────────────────────
                PrimaryButton(
                  label: 'Reset Password & Login',
                  onPressed: () => controller.updatePassword(formKey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Back to login button ─────────────────────────────────────────────────────

class _BackToLoginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 18),
          SizedBox(width: 4),
          Text(
            'BACK TO LOGIN',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
