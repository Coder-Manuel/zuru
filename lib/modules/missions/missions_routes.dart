import 'package:get/get.dart';
import 'package:zuru/core/routes/app_route.dart';
import 'package:zuru/core/routes/middlewares/client_only_middleware.dart';
import 'package:zuru/core/routes/middlewares/scout_only_middleware.dart';
import 'package:zuru/modules/missions/missions_bindings.dart';
import 'package:zuru/modules/missions/presentation/pages/finding_scouts_page.dart';
import 'package:zuru/modules/missions/presentation/pages/gps_verification_page.dart';
import 'package:zuru/modules/missions/presentation/pages/location_picker_page.dart';
import 'package:zuru/modules/missions/presentation/pages/mission_complete_page.dart';
import 'package:zuru/modules/missions/presentation/pages/mission_details_page.dart';
import 'package:zuru/modules/missions/presentation/pages/navigation_page.dart';
import 'package:zuru/modules/missions/presentation/pages/post_mission_page.dart';

class MissionsRoutes implements AppRoute {
  @override
  List<GetPage> pages = [
    // ── Client-only pages ─────────────────────────────────────────────────────
    GetPage(
      name: PostMissionPage.route,
      page: () => const PostMissionPage(),
      binding: MissionsBindings(),
      middlewares: [ClientOnlyMiddleware()],
    ),
    GetPage(
      name: FindingScoutsPage.route,
      page: () => const FindingScoutsPage(),
      binding: MissionsBindings(),
      middlewares: [ClientOnlyMiddleware()],
    ),
    GetPage(
      name: LocationPickerPage.route,
      page: () => const LocationPickerPage(),
      binding: MissionsBindings(),
      transition: Transition.rightToLeft,
      middlewares: [ClientOnlyMiddleware()],
    ),

    // ── Scout-only pages ──────────────────────────────────────────────────────
    GetPage(
      name: MissionDetailsPage.route,
      page: () => const MissionDetailsPage(),
      middlewares: [ScoutOnlyMiddleware()],
    ),
    GetPage(
      name: NavigationPage.route,
      page: () => const NavigationPage(),
      middlewares: [ScoutOnlyMiddleware()],
    ),
    GetPage(
      name: GpsVerificationPage.route,
      page: () => const GpsVerificationPage(),
      middlewares: [ScoutOnlyMiddleware()],
    ),

    // ── Shared ────────────────────────────────────────────────────────────────
    GetPage(
      name: MissionCompletePage.route,
      page: () => const MissionCompletePage(),
    ),
  ];
}
