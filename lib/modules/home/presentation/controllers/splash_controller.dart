import 'package:get/get.dart';
import 'package:zuru/core/services/theme_service/theme_service.dart';
import 'package:zuru/modules/auth/presentation/pages/login_page.dart';
import 'package:zuru/modules/home/presentation/pages/home_page.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

class SplashController extends GetxController {
  Future<void> checkIfUserIsLoggedIn() async {
    final userCTRL = Get.find<UserController>();
    await Future.delayed(const Duration(seconds: 2));
    await userCTRL.getUserDetails();
    final user = userCTRL.currentUser.value;
    if (user != null) {
      // TODO: route to ScoutHomePage and call applyScoutTheme() when role
      // selection / JWT claim-based routing is implemented.
      ThemeService.to.applyClientTheme();
      return Get.offAllNamed(HomePage.route);
    }

    return Get.offAllNamed(LoginPage.route);
  }
}
