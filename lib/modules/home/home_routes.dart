import 'package:get/get.dart';
import 'package:zuru/core/routes/app_route.dart';
import 'package:zuru/core/routes/app_routes.dart';
import 'package:zuru/core/routes/middlewares/home_role_middleware.dart';
import 'package:zuru/modules/home/presentation/pages/home_page.dart';
import 'package:zuru/modules/home/presentation/pages/scout_home_page.dart';
import 'package:zuru/modules/home/presentation/pages/splash_page.dart';

class HomeRoutes implements AppRoute {
  @override
  List<GetPage> pages = [
    GetPage(name: SplashPage.route, page: () => const SplashPage()),

    // ── /home — canonical entry point for both roles ──────────────────────────
    // HomeRoleMiddleware redirects scouts to /scout/home.
    // Clients land here and see HomePage directly.
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      middlewares: [HomeRoleMiddleware()],
    ),

    // ── /scout/home — reached only via HomeRoleMiddleware redirect ────────────
    GetPage(
      name: AppRoutes.scoutHome,
      page: () => const ScoutHomePage(),
    ),
  ];
}
