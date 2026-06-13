import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/modules/auth/data/repositories_impl/auth_repository_impl.dart';
import 'package:zuru/modules/auth/data/sources/remote_auth_datasource.dart';
import 'package:zuru/modules/auth/domain/repository/auth_repository.dart';
import 'package:zuru/modules/auth/domain/usecases/login.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/login_oauth.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/logout.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/register.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/send_reset_email.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/send_reset_otp.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/setup_names.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/setup_phone.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/update_password.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/update_scout_profile.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/verify_email_otp.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/verify_phone_otp.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/verify_reset_otp.usecase.dart';
import 'package:zuru/modules/auth/presentation/controllers/login_controller.dart';
import 'package:zuru/modules/auth/presentation/controllers/register_controller.dart';
import 'package:zuru/modules/auth/presentation/controllers/reset_password_controller.dart';

class AuthBindings extends Bindings {
  @override
  void dependencies() {
    // ── Data layer ────────────────────────────────────────────────────────────
    Get.lazyPut<RemoteAuthDatasource>(
      () => RemoteAuthDatasourceImpl(client: Get.find<SupabaseClient>()),
      fenix: true,
    );
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDatasource: Get.find<RemoteAuthDatasource>(),
      ),
      fenix: true,
    );

    // ── Use cases ─────────────────────────────────────────────────────────────
    Get.lazyPut<LoginUseCase>(
      () => LoginUseCase(repo: Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut<LoginOAuthUseCase>(
      () => LoginOAuthUseCase(repo: Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut<RegisterUsecase>(
      () => RegisterUsecase(repo: Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut<VerifyEmailOtpUseCase>(
      () => VerifyEmailOtpUseCase(repo: Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut<SetupPhoneUseCase>(
      () => SetupPhoneUseCase(repo: Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut<VerifyPhoneOtpUseCase>(
      () => VerifyPhoneOtpUseCase(repo: Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut<SetupNamesUseCase>(
      () => SetupNamesUseCase(repo: Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut<UpdateScoutBioUseCase>(
      () => UpdateScoutBioUseCase(repo: Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut<LogoutUseCase>(
      () => LogoutUseCase(repo: Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut<SendResetOtpUseCase>(
      () => SendResetOtpUseCase(repo: Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut<SendResetEmailUseCase>(
      () => SendResetEmailUseCase(repo: Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut<VerifyResetOtpUseCase>(
      () => VerifyResetOtpUseCase(repo: Get.find<AuthRepository>()),
      fenix: true,
    );
    Get.lazyPut<UpdatePasswordUseCase>(
      () => UpdatePasswordUseCase(repo: Get.find<AuthRepository>()),
      fenix: true,
    );

    // ── Controllers ───────────────────────────────────────────────────────────
    Get.lazyPut<LoginController>(() => LoginController(), fenix: true);
    Get.lazyPut<RegisterController>(() => RegisterController(), fenix: true);
    Get.lazyPut<ResetPasswordController>(
      () => ResetPasswordController(),
      fenix: true,
    );
  }
}
