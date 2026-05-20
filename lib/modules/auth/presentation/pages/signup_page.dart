import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/colors.dart';
import 'package:zuru/core/utils/extensions.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/auth/presentation/controllers/register_controller.dart';
import 'package:zuru/modules/auth/presentation/widgets/auth_widgets.dart';

class SignupPage extends GetView<RegisterController> {
  static const String route = '/signup';

  const SignupPage({super.key});

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
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chevron_left,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                      Text(
                        'Back to Login',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                40.verticalSpace,
                Text(
                  'Create Account',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                10.verticalSpace,
                Text(
                  'Join the network of scouts and clients.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
                32.verticalSpace,
                AuthTextField(
                  controller: controller.emailCTRL,
                  hint: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icon(
                    Icons.mail_outline,
                    color: AppColors.iconColor,
                    size: 20,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your email';
                    if (!v.isEmail) return 'Enter valid email';
                    return null;
                  },
                ),
                16.verticalSpace,
                Obx(
                  () => AuthTextField(
                    controller: controller.passwordCTRL,
                    hint: 'Password',
                    obscureText: controller.obscurePass.value,
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.iconColor,
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
                          color: AppColors.iconColor,
                          size: 20,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter your password';
                      if (v.length < 8) return 'Minimum 8 characters';
                      if (!v.isStrongPassword) {
                        return 'Atleast (Uppercase, lowercase, number & special char)';
                      }
                      return null;
                    },
                  ),
                ),
                16.verticalSpace,
                Obx(
                  () => AuthTextField(
                    controller: controller.confirmPasswordCTRL,
                    hint: 'Confirm Password',
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
                    validator: (v) => v != controller.passwordCTRL.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                ),
                36.verticalSpace,
                PrimaryButton(
                  label: 'Continue',
                  onPressed: () async => await controller.signUp(formKey),
                ),
                28.verticalSpace,
                const AuthDivider(text: 'OR'),
                28.verticalSpace,
                GoogleButton(
                  label:
                      'Continue with ${GetPlatform.isIOS ? 'Apple' : 'Google'}',
                  onPressed: () {},
                ),
                32.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
