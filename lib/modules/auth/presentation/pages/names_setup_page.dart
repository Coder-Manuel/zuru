import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/auth/presentation/controllers/register_controller.dart';
import 'package:zuru/modules/auth/presentation/widgets/auth_widgets.dart';

class NamesSetupPage extends GetView<RegisterController> {
  static const String route = '/names';

  const NamesSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: ClientColors.biometricBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: ClientColors.primary,
                    size: 36,
                  ),
                ),
                28.verticalSpace,
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Personal Details',
                    style: TextStyle(
                      color: ClientColors.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                10.verticalSpace,
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'How should we address you?',
                    style: TextStyle(
                      color: ClientColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
                28.verticalSpace,
                AuthTextField(
                  controller: controller.firstNameCTRL,
                  hint: 'First Name',
                  prefixIcon: const SizedBox.shrink(),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your first name' : null,
                ),
                16.verticalSpace,
                AuthTextField(
                  controller: controller.lastNameCTRL,
                  hint: 'Last Name',
                  prefixIcon: const SizedBox.shrink(),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your last name' : null,
                ),
                32.verticalSpace,
                PrimaryButton(
                  label: 'Complete Signup',
                  onPressed: () => controller.completeSignup(formKey),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
