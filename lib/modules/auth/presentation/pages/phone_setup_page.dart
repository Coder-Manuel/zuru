import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/auth/presentation/controllers/register_controller.dart';
import 'package:zuru/modules/auth/presentation/widgets/auth_widgets.dart';

class PhoneSetupPage extends GetView<RegisterController> {
  static const String route = '/phone-setup';

  const PhoneSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),
              Text(
                'Phone Number',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              12.verticalSpace,
              Text(
                'Required for mission coordination and security.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              28.verticalSpace,
              Row(
                children: [
                  Obx(
                    () => GestureDetector(
                      onTap: () => _showCountryPicker(context),
                      child: Container(
                        height: 58,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.inputBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          controller.countryCode.value,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: SizedBox(
                      height: 58,
                      child: TextField(
                        controller: controller.phoneCTRL,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: '712 345 678',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppColors.inputBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              32.verticalSpace,
              PrimaryButton(
                label: 'Update',
                onPressed: () async => await controller.setupPhone(),
              ),
              const Spacer(flex: 4),
            ],
          ),
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    final codes = ['+254', '+1', '+44', '+91', '+27', '+234', '+255', '+256'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: codes.length,
        separatorBuilder: (_, _) =>
            Divider(color: AppColors.divider, height: 1),
        itemBuilder: (_, i) => ListTile(
          title: Text(
            codes[i],
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
          onTap: () {
            controller.countryCode.value = codes[i];
            Get.back();
          },
        ),
      ),
    );
  }
}
