import 'package:get/get.dart';
import 'package:zuru/core/routes/app_route.dart';
import 'package:zuru/core/routes/middlewares/scout_only_middleware.dart';
import 'package:zuru/modules/user/domain/usecases/add_profile_clip.usecase.dart';
import 'package:zuru/modules/user/domain/usecases/delete_profile_clip.usecase.dart';
import 'package:zuru/modules/user/domain/usecases/get_profile_clips.usecase.dart';
import 'package:zuru/modules/user/domain/usecases/update_scout_profile.usecase.dart';
import 'package:zuru/modules/user/domain/usecases/upload_media.usecase.dart';
import 'package:zuru/modules/user/presentation/controllers/scout_profile_edit_controller.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';
import 'package:zuru/modules/user/presentation/pages/profile_page.dart';
import 'package:zuru/modules/user/presentation/pages/scout_profile_edit_page.dart';

class UserRoutes implements AppRoute {
  @override
  List<GetPage> pages = [
    GetPage(name: ProfilePage.route, page: () => const ProfilePage()),
    GetPage(
      name: ScoutProfileEditPage.route,
      page: () => const ScoutProfileEditPage(),
      middlewares: [ScoutOnlyMiddleware()],
      binding: BindingsBuilder(() {
        Get.lazyPut<ScoutProfileEditController>(
          () => ScoutProfileEditController(
            updateScoutProfile: Get.find<UpdateScoutProfileUseCase>(),
            uploadMedia: Get.find<UploadMediaUseCase>(),
            getProfileClips: Get.find<GetProfileClipsUseCase>(),
            addProfileClip: Get.find<AddProfileClipUseCase>(),
            deleteProfileClip: Get.find<DeleteProfileClipUseCase>(),
            userController: Get.find<UserController>(),
          ),
        );
      }),
    ),
  ];
}
