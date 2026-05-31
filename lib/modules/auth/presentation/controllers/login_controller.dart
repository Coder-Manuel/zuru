import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:zuru/core/services/theme_service/theme_service.dart';
import 'package:zuru/core/utils/loader.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/auth/data/models/auth.inputs.dart';
import 'package:zuru/modules/auth/domain/usecases/login.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/login_oauth.usecase.dart';
import 'package:zuru/modules/home/presentation/pages/home_page.dart';
import 'package:zuru/modules/home/presentation/pages/scout_home_page.dart';

class LoginController extends GetxController {
  final loginUsecase = Get.find<LoginUseCase>();
  final oathLoginUsecase = Get.find<LoginOAuthUseCase>();

  final emailCTRL = TextEditingController();
  final passwordCTRL = TextEditingController();

  Rx<bool> obscurePass = true.obs;
  Rx<bool> canLoginWithBiometrics = false.obs;

  void toggleObscurePass() => obscurePass.value = !obscurePass.value;

  /// Route to whichever home the currently selected role demands.
  void _navigateHome(String displayName) {
    Toast.success('Welcome $displayName');
    Get.offAllNamed(
      ThemeService.to.isScout ? ScoutHomePage.route : HomePage.route,
    );
  }

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

    response.fold(
      (ex) => Toast.error(ex.message),
      (data) => _navigateHome(data.displayName),
    );
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

    response.fold(
      (ex) => Toast.error(ex.message),
      (data) => _navigateHome(data.displayName),
    );
  }

  Future<void> login(GlobalKey<FormState> formKey) async {
    if (formKey.currentState?.validate() != true) return;

    Loader.show(message: 'Login...');
    final response = await loginUsecase(
      LoginInput(
        email: emailCTRL.text.trim(),
        password: passwordCTRL.text.trim(),
      ),
    );
    Loader.dismiss();

    response.fold(
      (ex) => Toast.error(ex.message),
      (data) => _navigateHome(data.displayName),
    );
  }
}
