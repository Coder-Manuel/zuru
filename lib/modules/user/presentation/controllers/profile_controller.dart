import 'package:get/get.dart';
import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/services/biometric_service/biometric_service.dart';
import 'package:zuru/core/services/storage_service/storage.service.dart';
import 'package:zuru/core/utils/loader.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/auth/domain/usecases/logout.usecase.dart';
import 'package:zuru/modules/auth/presentation/pages/login_page.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

class ProfileController extends GetxController {
  final LogoutUseCase _logoutUseCase;
  final UserController _userController;

  ProfileController({
    required LogoutUseCase logoutUseCase,
    required UserController userController,
  }) : _logoutUseCase = logoutUseCase,
       _userController = userController;

  final biometricsEnabled = false.obs;
  final isLoggingOut = false.obs;

  // ── Expose user state from UserController ─────────────────────────────────
  Rx<User?> get currentUser => _userController.currentUser;
  RxBool get notificationsEnabled => _userController.notificationsEnabled;

  @override
  void onInit() async {
    super.onInit();
    biometricsEnabled.value =
        await StorageService.get<bool>(StorageKeys.biometricsKey) ?? false;
    // Fetch user info if not already loaded.
    if (_userController.currentUser.value == null) {
      _userController.getUserDetails();
    }
  }

  Future<void> toggleBiometrics(bool value) async {
    if (value) {
      final supported = await BiometricService.isSupported();
      if (!supported) {
        Toast.error('Biometrics are not available on this device');
        return;
      }
      final verified = await BiometricService.authenticate(
        reason: 'Verify to enable biometric login',
      );
      if (!verified) return;
    }

    biometricsEnabled.value = value;
    await BiometricService.setEnabled(value);

    if (value && !await BiometricService.hasCredentials()) {
      Toast.info('Sign in with your password once to finish biometric setup');
    }
  }

  Future<void> toggleNotifications(bool value) =>
      _userController.toggleNotifications(value);

  Future<void> logout() async {
    isLoggingOut.value = true;
    Loader.show();
    final result = await _logoutUseCase();
    Loader.dismiss();
    isLoggingOut.value = false;

    result.fold(
      (err) => Toast.error(err.message),
      (_) => Get.offAllNamed(LoginPage.route),
    );
  }
}
