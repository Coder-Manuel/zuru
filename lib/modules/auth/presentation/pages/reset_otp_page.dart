import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:zuru/config/colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/auth/presentation/controllers/reset_password_controller.dart';
import 'package:zuru/modules/auth/presentation/widgets/auth_widgets.dart';

class ResetOtpPage extends GetView<ResetPasswordController> {
  static const String route = '/reset-otp';

  const ResetOtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              24.verticalSpace,

              // ── Back to login ───────────────────────────────────────────
              _BackToLoginButton(),

              const Spacer(flex: 1),

              // ── Shield icon ─────────────────────────────────────────────
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
              ),

              28.verticalSpace,

              // ── Heading ─────────────────────────────────────────────────
              Center(
                child: Text(
                  'Security Code',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              12.verticalSpace,
              Center(
                child: Text(
                  'Enter the 6-digit code sent to\n${controller.emailCTRL.text.trim()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),

              40.verticalSpace,

              // ── OTP boxes ───────────────────────────────────────────────
              Center(
                child: _ResetOtpField(
                  controller: controller.otpCTRL,
                  onCompleted: (_) => controller.verifyCode(),
                ),
              ),

              36.verticalSpace,

              // ── Verify button ───────────────────────────────────────────
              PrimaryButton(
                label: 'Verify Code',
                onPressed: controller.verifyCode,
              ),

              20.verticalSpace,

              // ── Resend ──────────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () =>
                      controller.sendResetCode(GlobalKey<FormState>()),
                  child: Text(
                    'Resend Code',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── OTP input — dark filled style ───────────────────────────────────────────

class _ResetOtpField extends StatelessWidget {
  final TextEditingController? controller;
  final void Function(String)? onCompleted;

  const _ResetOtpField({this.controller, this.onCompleted});

  @override
  Widget build(BuildContext context) {
    final defaultTheme = PinTheme(
      width: 52,
      height: 60,
      textStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );

    return Pinput(
      length: 6,
      showCursor: true,
      controller: controller,
      onCompleted: onCompleted,
      defaultPinTheme: defaultTheme,
      focusedPinTheme: defaultTheme.copyWith(
        decoration: defaultTheme.decoration!.copyWith(
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
      ),
      submittedPinTheme: defaultTheme,
      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
      separatorBuilder: (_) => 10.horizontalSpace,
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
