import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:zuru/config/colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/auth/presentation/controllers/register_controller.dart';
import 'package:zuru/modules/auth/presentation/widgets/auth_widgets.dart';

class VerifyPage extends GetView<RegisterController> {
  static const String route = '/verify';

  const VerifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isEmailVerification = Get.arguments ?? false;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.biometricBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEmailVerification
                      ? Icons.mail_outline
                      : Icons.phone_in_talk_outlined,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              28.verticalSpace,
              Text(
                'Verify ${isEmailVerification ? 'Email' : 'Phone'}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              12.verticalSpace,
              Text(
                "We've sent a 6-digit code to ${isEmailVerification ? controller.emailCTRL.text : controller.phoneCTRL.text}.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              80.verticalSpace,
              OtpInputField(
                controller: controller.otpCTRL,
                onCompleted: (otp) async {
                  if (isEmailVerification) {
                    return await controller.verifyEmail(otp);
                  }
                  return controller.verifyPhone(otp);
                },
              ),
              36.verticalSpace,
              PrimaryButton(
                label: 'Verify & Continue',
                onPressed: () async {
                  if (isEmailVerification) {
                    return await controller.verifyEmail(
                      controller.otpCTRL.text.trim(),
                    );
                  }
                  return controller.verifyPhone(controller.otpCTRL.text.trim());
                },
              ),
              20.verticalSpace,
              GestureDetector(
                onTap: () async {},
                child: Text(
                  'Resend Code',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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

class OtpInputField extends StatelessWidget {
  final TextEditingController? controller;
  final void Function(String)? onCompleted;
  const OtpInputField({super.key, this.controller, this.onCompleted});

  @override
  Widget build(BuildContext context) {
    return Pinput(
      length: 6,
      showCursor: true,
      controller: controller,
      onCompleted: onCompleted,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
      separatorBuilder: (_) => 15.horizontalSpace,
    );
  }

  PinTheme get defaultPinTheme => PinTheme(
    width: 45,
    height: 56,
    textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    decoration: BoxDecoration(
      border: Border.all(color: Color.fromRGBO(234, 239, 243, 1)),
      borderRadius: BorderRadius.circular(12),
    ),
  );
  PinTheme get focusedPinTheme => defaultPinTheme.copyDecorationWith(
    border: Border.all(color: AppColors.primary),
    borderRadius: BorderRadius.circular(8),
  );
}
