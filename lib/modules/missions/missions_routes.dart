import 'package:get/get.dart';
import 'package:zuru/core/routes/app_route.dart';
import 'package:zuru/modules/missions/missions_bindings.dart';
import 'package:zuru/modules/missions/presentation/pages/finding_scouts_page.dart';
import 'package:zuru/modules/missions/presentation/pages/location_picker_page.dart';
import 'package:zuru/modules/missions/presentation/pages/post_mission_page.dart';

class MissionsRoutes implements AppRoute {
  @override
  List<GetPage> pages = [
    GetPage(
      name: PostMissionPage.route,
      page: () => const PostMissionPage(),
      binding: MissionsBindings(),
    ),
    GetPage(
      name: FindingScoutsPage.route,
      page: () => const FindingScoutsPage(),
      binding: MissionsBindings(),
    ),
    GetPage(
      name: LocationPickerPage.route,
      page: () => const LocationPickerPage(),
      binding: MissionsBindings(),
      transition: Transition.rightToLeft,
    ),
  ];
}
