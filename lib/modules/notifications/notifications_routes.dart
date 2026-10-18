import 'package:get/get.dart';
import 'package:zuru/core/routes/app_route.dart';
import 'package:zuru/modules/notifications/presentation/pages/notifications_page.dart';

class NotificationsRoutes implements AppRoute {
  @override
  List<GetPage> pages = [
    GetPage(
      name: NotificationsPage.route,
      page: () => const NotificationsPage(),
    ),
  ];
}
