import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:zuru/config/colors.dart';
import 'package:zuru/modules/home/presentation/controllers/splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  static const String route = '/';
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: controller.checkIfUserIsLoggedIn(),
        builder: (_, _) {
          return SizedBox(
            height: Get.height,
            width: Get.width,
            child:
                Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(200),
                        child: const Text(
                          'Zuru World',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                    .animate(onPlay: (ctrl) => ctrl.repeat())
                    .shimmer(
                      duration: const Duration(seconds: 2),
                      color: AppColors.primary,
                    )
                    .animate()
                    .fadeIn(duration: const Duration(seconds: 2)),
          );
        },
      ),
    );
  }
}
