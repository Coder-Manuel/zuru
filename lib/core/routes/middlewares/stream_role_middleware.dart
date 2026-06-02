import 'package:get/get.dart';
import 'package:zuru/core/services/role_service/role_service.dart';
import 'package:zuru/modules/stream/presentation/pages/join_stream_page.dart';
import 'package:zuru/modules/stream/presentation/pages/stream_page.dart';

/// Intercepts every navigation to [AppRoutes.stream].
///
/// Instead of redirecting (which can lose [Get.arguments]), this middleware
/// uses [onPageCalled] to swap the page widget while keeping the route name
/// and any arguments (e.g. the [MissionEntity] passed by callers) intact.
///
/// Decision table:
/// | Active role | Page rendered    | Description            |
/// |-------------|------------------|------------------------|
/// | Scout       | [StreamPage]     | Broadcasts live feed   |
/// | Client      | [JoinStreamPage] | Watches live feed      |
///
/// Usage — add to the [GetPage] for [AppRoutes.stream]:
/// ```dart
/// GetPage(
///   name: AppRoutes.stream,
///   page: () => const JoinStreamPage(), // overridden below for scouts
///   middlewares: [StreamRoleMiddleware()],
/// )
/// ```
class StreamRoleMiddleware extends GetMiddleware {
  @override
  GetPage? onPageCalled(GetPage? page) {
    return page?.copy(
      page: RoleService.instance.isScout
          ? () => const StreamPage()
          : () => const JoinStreamPage(),
    );
  }
}
