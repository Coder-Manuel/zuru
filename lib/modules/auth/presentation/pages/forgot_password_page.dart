import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/auth/presentation/controllers/reset_password_controller.dart';
import 'package:zuru/modules/auth/presentation/widgets/auth_widgets.dart';

class ForgotPasswordPage extends GetView<ResetPasswordController> {
  static const String route = '/forgot-password';

  const ForgotPasswordPage({super.key});

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

                // ── Back to login ─────────────────────────────────────────
                _BackToLoginButton(),

                80.verticalSpace,

                // ── Heading ───────────────────────────────────────────────
                Text(
                  'Reset Password',
                  style: TextStyle(
                    color: ClientColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                16.verticalSpace,
                Text(
                  'Enter your email address below to\nreceive a password reset code.',
                  style: TextStyle(
                    color: ClientColors.textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),

                40.verticalSpace,

                // ── Email field ───────────────────────────────────────────
                AuthTextField(
                  controller: controller.emailCTRL,
                  hint: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icon(
                    Icons.mail_outline,
                    color: ClientColors.iconColor,
                    size: 20,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your email';
                    if (!v.isEmail) return 'Enter a valid email';
                    return null;
                  },
                ),

                24.verticalSpace,

                // ── Send button ───────────────────────────────────────────
                PrimaryButton(
                  label: 'Send Reset Code',
                  onPressed: () => controller.sendResetCode(formKey),
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
          Icon(Icons.chevron_left, color: ClientColors.textPrimary, size: 18),
          SizedBox(width: 4),
          Text(
            'BACK TO LOGIN',
            style: TextStyle(
              color: ClientColors.textPrimary,
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
