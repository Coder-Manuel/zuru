import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:zuru/core/utils/loader.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/auth/data/models/auth.inputs.dart';
import 'package:zuru/modules/auth/domain/usecases/send_reset_otp.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/update_password.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/verify_reset_otp.usecase.dart';
import 'package:zuru/modules/auth/presentation/pages/login_page.dart';
import 'package:zuru/modules/auth/presentation/pages/new_password_page.dart';
import 'package:zuru/modules/auth/presentation/pages/reset_otp_page.dart';

class ResetPasswordController extends GetxController {
  final _sendResetOtpUseCase = Get.find<SendResetOtpUseCase>();
  final _verifyResetOtpUseCase = Get.find<VerifyResetOtpUseCase>();
  final _updatePasswordUseCase = Get.find<UpdatePasswordUseCase>();

  // ── Form controllers ──────────────────────────────────────────────────────
  final emailCTRL = TextEditingController();
  final otpCTRL = TextEditingController();
  final newPasswordCTRL = TextEditingController();
  final confirmPasswordCTRL = TextEditingController();

  // ── Observable state ──────────────────────────────────────────────────────
  final RxBool obscureNewPass = true.obs;
  final RxBool obscureConfirmPass = true.obs;

  void toggleObscureNewPass() => obscureNewPass.value = !obscureNewPass.value;
  void toggleObscureConfirmPass() =>
      obscureConfirmPass.value = !obscureConfirmPass.value;

  // ── Step 1 — Send reset OTP ───────────────────────────────────────────────

  Future<void> sendResetCode(GlobalKey<FormState> formKey) async {
    if (formKey.currentState?.validate() != true) return;

    Loader.show(message: 'Sending reset code…');
    final response = await _sendResetOtpUseCase(
      ResetPasswordInput(email: emailCTRL.text.trim()),
    );
    Loader.dismiss();

    response.fold(
      (err) => Toast.error(err.message),
      (_) => Get.toNamed(ResetOtpPage.route),
    );
  }

  // ── Step 2 — Verify OTP ───────────────────────────────────────────────────

  Future<void> verifyCode() async {
    final otp = otpCTRL.text.trim();
    if (otp.length < 6) {
      Toast.error('Enter the full 6-digit code.');
      return;
    }

    Loader.show(message: 'Verifying code…');
    final response = await _verifyResetOtpUseCase(
      VerifyOtpInput.email(otp: otp, email: emailCTRL.text.trim()),
    );
    Loader.dismiss();

    response.fold(
      (err) => Toast.error(err.message),
      (_) => Get.toNamed(NewPasswordPage.route),
    );
  }

  // ── Step 3 — Set new password ─────────────────────────────────────────────

  Future<void> updatePassword(GlobalKey<FormState> formKey) async {
    if (formKey.currentState?.validate() != true) return;

    Loader.show(message: 'Updating password…');
    final response = await _updatePasswordUseCase(
      UpdatePasswordInput(newPassword: newPasswordCTRL.text),
    );
    Loader.dismiss();

    response.fold((err) => Toast.error(err.message), (_) {
      Toast.success('Password updated! Please log in.');
      // Clear all reset state and go back to login, removing the reset stack.
      otpCTRL.clear();
      newPasswordCTRL.clear();
      confirmPasswordCTRL.clear();
      Get.until((route) => route.settings.name == LoginPage.route);
    });
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  @override
  void onClose() {
    emailCTRL.dispose();
    otpCTRL.dispose();
    newPasswordCTRL.dispose();
    confirmPasswordCTRL.dispose();
    super.onClose();
  }
}
