import 'package:get/get.dart';
import 'package:zuru/core/routes/app_route.dart';
import 'package:zuru/modules/home/presentation/pages/splash_page.dart';

class HomeRoutes implements AppRoute {
  @override
  List<GetPage> pages = [
    GetPage(name: SplashPage.route, page: () => const SplashPage()),
    // TODO(Phase 2): Add HomePage, and remaining home routes
  ];
}
