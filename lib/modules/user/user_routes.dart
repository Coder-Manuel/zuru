import 'package:get/get.dart';
import 'package:zuru/core/routes/app_route.dart';
import 'package:zuru/modules/user/presentation/pages/profile_page.dart';

class UserRoutes implements AppRoute {
  @override
  List<GetPage> pages = [
    GetPage(name: ProfilePage.route, page: () => const ProfilePage()),
  ];
}
