import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/modules/auth/domain/usecases/logout.usecase.dart';
import 'package:zuru/modules/user/data/repositories_impl/user_repository_impl.dart';
import 'package:zuru/modules/user/data/sources/remote_user_datasource.dart';
import 'package:zuru/modules/user/domain/repository/user_repository.dart';
import 'package:zuru/modules/user/domain/usecases/add_profile_clip.usecase.dart';
import 'package:zuru/modules/user/domain/usecases/delete_profile_clip.usecase.dart';
import 'package:zuru/modules/user/domain/usecases/get_profile_clips.usecase.dart';
import 'package:zuru/modules/user/domain/usecases/get_user_info.usecase.dart';
import 'package:zuru/modules/user/domain/usecases/update_default_role.usecase.dart';
import 'package:zuru/modules/user/domain/usecases/update_fcm_token.usecase.dart';
import 'package:zuru/modules/user/domain/usecases/update_scout_profile.usecase.dart';
import 'package:zuru/modules/user/domain/usecases/upload_media.usecase.dart';
import 'package:zuru/modules/user/presentation/controllers/profile_controller.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

class UserBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RemoteUserDatasource>(
      () => RemoteUserDatasourceImpl(client: Get.find<SupabaseClient>()),
      fenix: true,
    );
    Get.lazyPut<UserRepository>(
      () => UserRepositoryImpl(
        remoteDatasource: Get.find<RemoteUserDatasource>(),
      ),
      fenix: true,
    );
    Get.lazyPut<GetUserInfoUseCase>(
      () => GetUserInfoUseCase(repo: Get.find<UserRepository>()),
      fenix: true,
    );
    Get.lazyPut<UpdateFcmTokenUseCase>(
      () => UpdateFcmTokenUseCase(repo: Get.find<UserRepository>()),
      fenix: true,
    );
    Get.lazyPut<UpdateDefaultRoleUseCase>(
      () => UpdateDefaultRoleUseCase(repo: Get.find<UserRepository>()),
      fenix: true,
    );

    // ── Scout World Profile use-cases ─────────────────────────────────────
    Get.lazyPut<UpdateScoutProfileUseCase>(
      () => UpdateScoutProfileUseCase(repo: Get.find<UserRepository>()),
      fenix: true,
    );
    Get.lazyPut<UploadMediaUseCase>(
      () => UploadMediaUseCase(repo: Get.find<UserRepository>()),
      fenix: true,
    );
    Get.lazyPut<GetProfileClipsUseCase>(
      () => GetProfileClipsUseCase(repo: Get.find<UserRepository>()),
      fenix: true,
    );
    Get.lazyPut<AddProfileClipUseCase>(
      () => AddProfileClipUseCase(repo: Get.find<UserRepository>()),
      fenix: true,
    );
    Get.lazyPut<DeleteProfileClipUseCase>(
      () => DeleteProfileClipUseCase(repo: Get.find<UserRepository>()),
      fenix: true,
    );

    Get.put<UserController>(UserController(), permanent: true);

    Get.lazyPut<ProfileController>(
      () => ProfileController(
        logoutUseCase: Get.find<LogoutUseCase>(),
        userController: Get.find<UserController>(),
      ),
      fenix: true,
    );

    // NOTE: [ScoutProfileEditController] is intentionally NOT registered here.
    // It is bound per-navigation via [ScoutProfileEditBinding] on its route so
    // its editable state + text controllers are created and disposed fresh on
    // each visit.
  }
}
