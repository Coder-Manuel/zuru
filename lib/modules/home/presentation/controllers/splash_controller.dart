import 'package:get/get.dart';
import 'package:zuru/modules/auth/presentation/pages/login_page.dart';
import 'package:zuru/modules/home/presentation/pages/home_page.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

class SplashController extends GetxController {
  Future<void> checkIfUserIsLoggedIn() async {
    final userCTRL = Get.find<UserController>();
    await Future.delayed(Duration(seconds: 2));
    await userCTRL.getUserDetails();
    final user = userCTRL.currentUser.value;
    if (user != null) {
      return Get.offAllNamed(HomePage.route);
    }

    return Get.offAllNamed(LoginPage.route);
  }
}
