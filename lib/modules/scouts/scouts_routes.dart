import 'package:get/get.dart';
import 'package:zuru/core/routes/app_route.dart';
import 'package:zuru/core/routes/middlewares/client_only_middleware.dart';
import 'package:zuru/modules/scouts/domain/usecases/get_scout_detail.usecase.dart';
import 'package:zuru/modules/scouts/presentation/controllers/scout_detail_controller.dart';
import 'package:zuru/modules/scouts/presentation/pages/scout_detail_page.dart';

class ScoutsRoutes implements AppRoute {
  @override
  List<GetPage> pages = [
    GetPage(
      name: ScoutDetailPage.route,
      page: () => const ScoutDetailPage(),
      transition: Transition.rightToLeft,
      middlewares: [ClientOnlyMiddleware()],
      binding: BindingsBuilder(() {
        Get.lazyPut<ScoutDetailController>(
          () => ScoutDetailController(
            getScoutDetail: Get.find<GetScoutDetailUseCase>(),
          ),
        );
      }),
    ),
  ];
}
