import 'package:get/get.dart';
import 'package:zuru/core/routes/app_route.dart';
import 'package:zuru/modules/home/presentation/pages/home_page.dart';
import 'package:zuru/modules/home/presentation/pages/splash_page.dart';

class HomeRoutes implements AppRoute {
  @override
  List<GetPage> pages = [
    GetPage(name: HomePage.route, page: () => const HomePage()),
    GetPage(name: SplashPage.route, page: () => const SplashPage()),
  ];
}
