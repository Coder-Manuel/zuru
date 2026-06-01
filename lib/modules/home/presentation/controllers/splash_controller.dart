import 'package:get/get.dart';
import 'package:zuru/core/routes/app_routes.dart';
import 'package:zuru/modules/auth/presentation/pages/login_page.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

class SplashController extends GetxController {
  Future<void> checkIfUserIsLoggedIn() async {
    final userCTRL = Get.find<UserController>();
    await Future.delayed(const Duration(seconds: 2));
    await userCTRL.getUserDetails();
    final user = userCTRL.currentUser.value;

    if (user != null) {
      // ThemeService.onInit() already restored the persisted role from storage.
      // HomeRoleMiddleware on AppRoutes.home resolves the correct home page.
      return Get.offAllNamed(AppRoutes.home);
    }

    return Get.offAllNamed(LoginPage.route);
  }
}
