// Widget test for [ForgotPasswordPage] in isolation.
//
// "Isolated" here means: the real page + real [ResetPasswordController], but the
// controller's use cases are backed by a *mocked* [AuthRepository]. We exercise
// pure UI concerns — rendering and client-side form validation — and assert
// that an invalid form never reaches the repository.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:zuru/modules/auth/domain/usecases/send_reset_otp.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/update_password.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/verify_reset_otp.usecase.dart';
import 'package:zuru/modules/auth/presentation/controllers/reset_password_controller.dart';
import 'package:zuru/modules/auth/presentation/pages/forgot_password_page.dart';

import '../../helpers/test_mocks.mocks.dart';

void main() {
  late MockAuthRepository repo;

  setUp(() {
    Get.testMode = true;
    repo = MockAuthRepository();
    // The controller resolves its use cases from GetX at construction time.
    Get.put<SendResetOtpUseCase>(SendResetOtpUseCase(repo: repo));
    Get.put<VerifyResetOtpUseCase>(VerifyResetOtpUseCase(repo: repo));
    Get.put<UpdatePasswordUseCase>(UpdatePasswordUseCase(repo: repo));
    Get.put<ResetPasswordController>(ResetPasswordController());
  });

  tearDown(Get.reset);

  Future<void> pumpPage(WidgetTester tester) {
    return tester.pumpWidget(const GetMaterialApp(home: ForgotPasswordPage()));
  }

  testWidgets('renders the heading, email field and submit button', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Send Reset Code'),
      findsOneWidget,
    );
  });

  testWidgets('shows a required-field error and does not call the repo', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Reset Code'));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    verifyNever(repo.sendPasswordResetOtp(any));
  });

  testWidgets('shows an invalid-email error and does not call the repo', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Reset Code'));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
    verifyNever(repo.sendPasswordResetOtp(any));
  });
}
