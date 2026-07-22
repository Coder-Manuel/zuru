import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:zuru/core/routes/app_routes.dart';
import 'package:zuru/core/services/biometric_service/biometric_service.dart';
import 'package:zuru/core/utils/loader.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/auth/data/models/auth.inputs.dart';
import 'package:zuru/modules/auth/domain/usecases/login.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/login_oauth.usecase.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

class LoginController extends GetxController {
  final loginUsecase = Get.find<LoginUseCase>();
  final oathLoginUsecase = Get.find<LoginOAuthUseCase>();

  final emailCTRL = TextEditingController();
  final passwordCTRL = TextEditingController();

  Rx<bool> obscurePass = true.obs;
  Rx<bool> canLoginWithBiometrics = false.obs;

  @override
  void onInit() {
    super.onInit();
    _resolveBiometricAvailability();
  }

  Future<void> _resolveBiometricAvailability() async {
    final enabled = await BiometricService.isEnabled();
    if (!enabled) return;
    final supported = await BiometricService.isSupported();
    final hasCreds = await BiometricService.hasCredentials();
    canLoginWithBiometrics.value = supported && hasCreds;
  }

  void toggleObscurePass() => obscurePass.value = !obscurePass.value;

  // ── Post-login destination resolution ─────────────────────────────────────

  /// Fetches fresh user data to check profile completeness, then navigates to
  /// the correct destination. [HomeRoleMiddleware] handles the final
  /// client/scout split at [AppRoutes.home].
  void _navigateHome() => _checkAndNavigate();

  Future<void> _checkAndNavigate() async {
    Loader.show(message: 'Loading profile...');
    final userCTRL = Get.find<UserController>();
    await userCTRL.getUserDetails();
    Loader.dismiss();

    final user = userCTRL.currentUser.value;
    // Greet with the active-role display name once the profile is loaded.
    final name = user?.profile?.displayName ?? 'back';
    Toast.success('Welcome $name!');

    Get.offAllNamed(
      user != null ? userCTRL.resolvePostAuthDestination(user) : AppRoutes.home,
    );
  }

  // ── OAuth ──────────────────────────────────────────────────────────────────

  Future<void> oathLogin() async {
    if (!GetPlatform.isIOS) return _appleLogin();
    return _googleLogin();
  }

  Future<void> _googleLogin() async {
    await GoogleSignIn.instance.initialize();
    final oathResult = await GoogleSignIn.instance.authenticate();
    if (oathResult.authentication.idToken == null) {
      return Toast.error('Unable to initiate google login');
    }

    final response = await oathLoginUsecase(
      OAuthInput(idToken: oathResult.authentication.idToken ?? ''),
    );

    response.fold((ex) => Toast.error(ex.message), (_) => _navigateHome());
  }

  Future<void> _appleLogin() async {
    await GoogleSignIn.instance.initialize();
    final oathResult = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    if (oathResult.identityToken == null) {
      return Toast.error('Unable to initiate apple login');
    }

    final response = await oathLoginUsecase(
      OAuthInput(idToken: oathResult.identityToken ?? ''),
    );

    response.fold((ex) => Toast.error(ex.message), (_) => _navigateHome());
  }

  // ── Email / password login ─────────────────────────────────────────────────

  Future<void> login(GlobalKey<FormState> formKey) async {
    if (formKey.currentState?.validate() != true) return;

    final email = emailCTRL.text.trim();
    final password = passwordCTRL.text.trim();

    Loader.show(message: 'Login...');
    final response = await loginUsecase(
      LoginInput(email: email, password: password),
    );
    Loader.dismiss();

    response.fold((ex) => Toast.error(ex.message), (_) async {
      await BiometricService.saveCredentials(email: email, password: password);
      _navigateHome();
    });
  }

  Future<void> biometricLogin() async {
    final verified = await BiometricService.authenticate(
      reason: 'Verify to sign in',
    );
    if (!verified) return;

    final creds = await BiometricService.readCredentials();
    if (creds == null) {
      Toast.error('No saved sign-in. Please log in with your password.');
      return;
    }

    Loader.show(message: 'Login...');
    final response = await loginUsecase(
      LoginInput(email: creds.email, password: creds.password),
    );
    Loader.dismiss();

    response.fold((ex) => Toast.error(ex.message), (_) => _navigateHome());
  }
}
