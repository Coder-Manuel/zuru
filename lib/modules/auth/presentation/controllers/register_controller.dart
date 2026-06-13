import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:zuru/core/routes/app_routes.dart';
import 'package:zuru/core/services/role_service/role_service.dart';
import 'package:zuru/core/utils/loader.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/auth/data/models/auth.inputs.dart';
import 'package:zuru/modules/auth/data/models/scout_profile.input.dart';
import 'package:zuru/modules/auth/domain/usecases/register.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/setup_names.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/setup_phone.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/update_scout_profile.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/verify_email_otp.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/verify_phone_otp.usecase.dart';
import 'package:zuru/modules/auth/presentation/pages/names_setup_page.dart';
import 'package:zuru/modules/auth/presentation/pages/phone_setup_page.dart';
import 'package:zuru/modules/auth/presentation/pages/verify_page.dart';

class RegisterController extends GetxController {
  final _signupUsecase = Get.find<RegisterUsecase>();
  final _setupPhoneUsecase = Get.find<SetupPhoneUseCase>();
  final _verifyPhoneOtpUsecase = Get.find<VerifyPhoneOtpUseCase>();
  final _verifyEmailOtpUsecase = Get.find<VerifyEmailOtpUseCase>();
  final _setupNamesUsecase = Get.find<SetupNamesUseCase>();
  final _updateScoutProfileUsecase = Get.find<UpdateScoutBioUseCase>();

  // ─── Step 1 — Credentials ─────────────────────────────────────────────────
  final emailCTRL = TextEditingController();
  final passwordCTRL = TextEditingController();
  final confirmPasswordCTRL = TextEditingController();
  RxBool obscurePass = true.obs;
  RxBool obscureConfirmPass = true.obs;

  void toggleObscurePass() => obscurePass.value = !obscurePass.value;
  void toggleObscureConfirmPass() =>
      obscureConfirmPass.value = !obscureConfirmPass.value;

  // ─── Step 2 — Phone (scouts only) ─────────────────────────────────────────
  final phoneCTRL = TextEditingController();
  RxString countryCode = '+254'.obs;

  // ─── Step 3 — OTP ─────────────────────────────────────────────────────────
  final otpCTRL = TextEditingController();

  // ─── Step 4 — Names ───────────────────────────────────────────────────────
  final firstNameCTRL = TextEditingController();
  final lastNameCTRL = TextEditingController();

  // ─── Step 5 — Scout "About Me" ────────────────────────────────────────────
  final bioCTRL = TextEditingController();
  final RxList<String> selectedTags = <String>[].obs;

  void toggleTag(String tag) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> signUp(GlobalKey<FormState> formKey) async {
    if (formKey.currentState?.validate() != true) return;

    Loader.show(message: 'Creating account...');
    final response = await _signupUsecase(
      SignupInput(
        email: emailCTRL.text.trim(),
        password: passwordCTRL.text.trim(),
        role: RoleService.instance.role.value,
      ),
    );
    Loader.dismiss();

    response.fold(
      (ex) => Toast.error(ex.message),
      (_) => Get.toNamed(VerifyPage.route, arguments: true),
    );
  }

  /// After email OTP verification:
  /// - **Scouts** → phone setup → (verify phone OTP) → names → about me → home
  /// - **Clients** → names → home  (no phone step)
  Future<void> verifyEmail(String otp) async {
    if (otp.length < 6) {
      Toast.error('Enter the 6-digit code');
      return;
    }

    Loader.show(message: 'Verifying...');
    final response = await _verifyEmailOtpUsecase(
      VerifyOtpInput.email(otp: otp, email: emailCTRL.text.trim()),
    );
    Loader.dismiss();

    response.fold(
      (ex) => Toast.error(ex.message),
      (_) => RoleService.instance.isScout
          ? Get.toNamed(PhoneSetupPage.route)
          : Get.toNamed(NamesSetupPage.route),
    );
  }

  Future<void> setupPhone() async {
    final phone = phoneCTRL.text.trim();
    if (phone.isEmpty) {
      Toast.error('Enter a valid phone number');
      return;
    }

    Loader.show(message: 'Updating phone...');
    final response = await _setupPhoneUsecase(
      PhoneSetupInput(phone: '${countryCode.value}$phone'),
    );
    Loader.dismiss();

    response.fold(
      (ex) => Toast.error(ex.message),
      (_) => Get.toNamed(NamesSetupPage.route),
    );
  }

  Future<void> verifyPhone(String otp) async {
    if (otp.length < 6) {
      Toast.error('Enter the 6-digit code');
      return;
    }

    Loader.show(message: 'Verifying...');
    final response = await _verifyPhoneOtpUsecase(
      VerifyOtpInput.phone(
        otp: otp,
        phone: '${countryCode.value}${phoneCTRL.text.trim()}',
      ),
    );
    Loader.dismiss();

    response.fold(
      (ex) => Toast.error(ex.message),
      (_) => Get.toNamed(NamesSetupPage.route),
    );
  }

  /// After names are saved:
  /// - **Scouts** → scout "About Me" page
  /// - **Clients** → home
  Future<void> completeSignup(GlobalKey<FormState> formKey) async {
    if (formKey.currentState?.validate() != true) return;

    Loader.show(message: 'Almost done...');
    final input = NamesInput(
      firstName: firstNameCTRL.text.trim(),
      lastName: lastNameCTRL.text.trim(),
    );
    if (RoleService.instance.isClient) input.status = 'active';
    final response = await _setupNamesUsecase(input);
    Loader.dismiss();

    response.fold(
      (ex) => Toast.error(ex.message),
      (_) => RoleService.instance.isScout
          ? Get.toNamed(AppRoutes.scoutAboutMe)
          : Get.offAllNamed(AppRoutes.home),
    );
  }

  /// Scout "About Me" — saves bio + tags then navigates home.
  Future<void> updateScoutProfile() async {
    final bio = bioCTRL.text.trim();
    if (bio.isEmpty) {
      Toast.error('Please write a brief bio');
      return;
    }
    if (selectedTags.isEmpty) {
      Toast.error('Select at least one skill tag');
      return;
    }

    Loader.show(message: 'Saving profile...');
    final response = await _updateScoutProfileUsecase(
      ScoutProfileInput(bio: bio, tags: selectedTags.toList()),
    );
    Loader.dismiss();

    response.fold(
      (ex) => Toast.error(ex.message),
      (_) => Get.offAllNamed(AppRoutes.home),
    );
  }

  @override
  void onClose() {
    emailCTRL.dispose();
    passwordCTRL.dispose();
    confirmPasswordCTRL.dispose();
    phoneCTRL.dispose();
    otpCTRL.dispose();
    firstNameCTRL.dispose();
    lastNameCTRL.dispose();
    bioCTRL.dispose();
    super.onClose();
  }
}
