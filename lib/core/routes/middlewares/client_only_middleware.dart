import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:zuru/core/routes/app_routes.dart';
import 'package:zuru/core/services/role_service/role_service.dart';

/// Guards routes that are exclusively for clients.
///
/// If a scout somehow navigates to a client-only page, they are redirected
/// to [AppRoutes.home] which [HomeRoleMiddleware] will resolve to
/// [ScoutHomePage].
///
/// Apply to client-specific [GetPage] registrations:
/// ```dart
/// GetPage(
///   name: AppRoutes.postMission,
///   page: () => const PostMissionPage(),
///   middlewares: [ClientOnlyMiddleware()],
/// )
/// ```
class ClientOnlyMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!RoleService.instance.isClient) {
      return const RouteSettings(name: AppRoutes.home);
    }
    return null; // client — proceed normally
  }
}
