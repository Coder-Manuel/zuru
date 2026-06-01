import 'package:get/get.dart';
import 'package:zuru/modules/auth/presentation/pages/login_page.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

class SplashController extends GetxController {
  Future<void> checkIfUserIsLoggedIn() async {
    final userCTRL = Get.find<UserController>();
    await Future.delayed(const Duration(seconds: 2));
    await userCTRL.getUserDetails();
    final user = userCTRL.currentUser.value;

    if (user != null) {
      // resolvePostAuthDestination checks phone, names, status, and (for
      // scouts) bio completeness, then returns the correct AppRoutes constant.
      return Get.offAllNamed(userCTRL.resolvePostAuthDestination(user));
    }

    return Get.offAllNamed(LoginPage.route);
  }
}
