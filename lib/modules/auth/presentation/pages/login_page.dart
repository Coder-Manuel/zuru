import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
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
                Text(
                  'UnSeen',
                  style: TextStyle(
                    color: ClientColors.textPrimary,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                8.verticalSpace,
                Text(
                  'See anywhere. Know everything.',
                  style: TextStyle(
                    color: ClientColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
                60.verticalSpace,
                AuthTextField(
                  controller: controller.emailCTRL,
                  hint: 'Email address',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icon(
                    Icons.mail_outline,
                    color: ClientColors.iconColor,
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
                      color: ClientColors.iconColor,
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
                          color: ClientColors.iconColor,
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
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Get.toNamed(ForgotPasswordPage.route),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: ClientColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                38.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Login',
                        onPressed: () async => await controller.login(formKey),
                      ),
                    ),
                    if (controller.canLoginWithBiometrics.value) ...[
                      15.horizontalSpace,
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 65,
                          height: 55,
                          decoration: BoxDecoration(
                            color: ClientColors.surface,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.fingerprint,
                            color: ClientColors.primary,
                            size: 36,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                40.verticalSpace,
                const AuthDivider(),
                40.verticalSpace,
                GoogleButton(
                  label:
                      'Continue with ${GetPlatform.isIOS ? 'Apple' : 'Google'}',
                  onPressed: () async => await controller.oathLogin(),
                ),
                30.verticalSpace,
                GestureDetector(
                  onTap: () => Get.toNamed(SignupPage.route),
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                        color: ClientColors.textSecondary,
                        fontSize: 15,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: ClientColors.primary,
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
