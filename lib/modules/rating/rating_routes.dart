import 'package:get/get.dart';
import 'package:zuru/core/routes/app_route.dart';
import 'package:zuru/modules/rating/presentation/pages/rate_scout_page.dart';

class RatingRoutes implements AppRoute {
  @override
  List<GetPage> pages = [
    GetPage(name: RateScoutPage.route, page: () => const RateScoutPage()),
  ];
}
