import 'package:get/get.dart';
import 'package:zuru/modules/auth/auth_routes.dart';
import 'package:zuru/modules/home/home_routes.dart';
import 'package:zuru/modules/missions/missions_routes.dart';
import 'package:zuru/modules/payments/payments_routes.dart';
import 'package:zuru/modules/rating/rating_routes.dart';
import 'package:zuru/modules/scouts/scouts_routes.dart';
import 'package:zuru/modules/stream/stream_routes.dart';
import 'package:zuru/modules/user/user_routes.dart';

class AppPages {
  static final List<GetPage> routes = [
    ...HomeRoutes().pages,
    ...AuthRoutes().pages,
    ...MissionsRoutes().pages,
    ...StreamRoutes().pages,
    ...RatingRoutes().pages,
    ...PaymentsRoutes().pages,
    ...UserRoutes().pages,
    ...ScoutsRoutes().pages,
  ];
}
