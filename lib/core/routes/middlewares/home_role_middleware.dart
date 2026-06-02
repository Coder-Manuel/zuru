import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:zuru/core/routes/app_routes.dart';
import 'package:zuru/core/services/role_service/role_service.dart';

/// Intercepts every navigation to [AppRoutes.home].
///
/// Decision table:
/// | Active role | Outcome                                        |
/// |-------------|------------------------------------------------|
/// | Scout       | Redirected to [AppRoutes.scoutHome]            |
/// | Client      | Proceeds normally → [HomePage] is rendered    |
///
/// Usage — add to the [GetPage] for [AppRoutes.home]:
/// ```dart
/// GetPage(
///   name: AppRoutes.home,
///   page: () => const HomePage(),
///   middlewares: [HomeRoleMiddleware()],
/// )
/// ```
class HomeRoleMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (RoleService.instance.isScout) {
      return const RouteSettings(name: AppRoutes.scoutHome);
    }
    return null; // client — render HomePage directly
  }
}
