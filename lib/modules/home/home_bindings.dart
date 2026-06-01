import 'package:get/get.dart';
import 'package:zuru/modules/home/presentation/controllers/home_controller.dart';
import 'package:zuru/modules/home/presentation/controllers/maps_tab_controller.dart';
import 'package:zuru/modules/home/presentation/controllers/splash_controller.dart';

class HomeBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<HomeController>(HomeController(), permanent: true);
    Get.lazyPut<SplashController>(() => SplashController(), fenix: true);
    Get.lazyPut<MapsTabController>(() => MapsTabController(), fenix: true);
  }
}
