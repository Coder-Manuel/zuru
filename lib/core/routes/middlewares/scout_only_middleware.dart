import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:zuru/core/routes/app_routes.dart';
import 'package:zuru/core/services/role_service/role_service.dart';

/// Guards routes that are exclusively for scouts.
///
/// If a client somehow navigates to a scout-only page, they are redirected
/// to [AppRoutes.home] which [HomeRoleMiddleware] will resolve to [HomePage].
///
/// Apply to scout-specific [GetPage] registrations:
/// ```dart
/// GetPage(
///   name: AppRoutes.missionDetails,
///   page: () => const MissionDetailsPage(),
///   middlewares: [ScoutOnlyMiddleware()],
/// )
/// ```
class ScoutOnlyMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!RoleService.instance.isScout) {
      return const RouteSettings(name: AppRoutes.home);
    }
    return null; // scout — proceed normally
  }
}
