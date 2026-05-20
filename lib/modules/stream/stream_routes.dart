import 'package:get/get.dart';
import 'package:zuru/core/routes/app_route.dart';
import 'package:zuru/modules/stream/presentation/pages/join_stream_page.dart';
import 'package:zuru/modules/stream/presentation/pages/stream_page.dart';

class StreamRoutes implements AppRoute {
  @override
  List<GetPage> pages = [
    GetPage(name: JoinStreamPage.route, page: () => const JoinStreamPage()),
    GetPage(name: StreamPage.route, page: () => const StreamPage()),
  ];
}
