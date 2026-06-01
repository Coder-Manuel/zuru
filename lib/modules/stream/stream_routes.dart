import 'package:get/get.dart';
import 'package:zuru/core/routes/app_route.dart';
import 'package:zuru/core/routes/app_routes.dart';
import 'package:zuru/core/routes/middlewares/stream_role_middleware.dart';
import 'package:zuru/modules/stream/presentation/pages/join_stream_page.dart';

class StreamRoutes implements AppRoute {
  @override
  List<GetPage> pages = [
    // ── /stream — canonical entry point for live sessions ─────────────────────
    // StreamRoleMiddleware swaps the page widget based on the active role:
    //   Scout  → StreamPage     (broadcasts the live feed)
    //   Client → JoinStreamPage (watches the live feed)
    //
    // All call-sites should navigate to AppRoutes.stream and pass the active
    // MissionEntity as Get.arguments.  The middleware preserves arguments.
    GetPage(
      name: AppRoutes.stream,
      page: () => const JoinStreamPage(), // swapped by StreamRoleMiddleware
      middlewares: [StreamRoleMiddleware()],
    ),
  ];
}
