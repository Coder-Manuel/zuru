// Integration test: UI → controller → use case → real repository → MOCK datasource.
//
// Everything above the network is real. Only [RemoteAuthDatasource] is mocked,
// so a tap on the real [ForgotPasswordPage] drives the whole auth stack down to
// the datasource boundary and back, and we assert the resulting navigation /
// error behaviour.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:zuru/modules/auth/data/repositories_impl/auth_repository_impl.dart';
import 'package:zuru/modules/auth/domain/repository/auth_repository.dart';
import 'package:zuru/modules/auth/domain/usecases/send_reset_otp.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/update_password.usecase.dart';
import 'package:zuru/modules/auth/domain/usecases/verify_reset_otp.usecase.dart';
import 'package:zuru/modules/auth/presentation/controllers/reset_password_controller.dart';
import 'package:zuru/modules/auth/presentation/pages/forgot_password_page.dart';
import 'package:zuru/modules/auth/presentation/pages/reset_otp_page.dart';

import '../../helpers/test_mocks.mocks.dart';

void main() {
  late MockRemoteAuthDatasource ds;

  setUp(() {
    Get.testMode = true;
    ds = MockRemoteAuthDatasource();

    // Real repository + real use cases wired to the mocked datasource.
    Get.put<AuthRepository>(AuthRepositoryImpl(remoteDatasource: ds));
    Get.put<SendResetOtpUseCase>(
      SendResetOtpUseCase(repo: Get.find<AuthRepository>()),
    );
    Get.put<VerifyResetOtpUseCase>(
      VerifyResetOtpUseCase(repo: Get.find<AuthRepository>()),
    );
    Get.put<UpdatePasswordUseCase>(
      UpdatePasswordUseCase(repo: Get.find<AuthRepository>()),
    );
    Get.put<ResetPasswordController>(ResetPasswordController());
  });

  tearDown(Get.reset);

  Future<void> pumpApp(WidgetTester tester) {
    return tester.pumpWidget(
      GetMaterialApp(
        initialRoute: ForgotPasswordPage.route,
        getPages: [
          GetPage(
            name: ForgotPasswordPage.route,
            page: () => const ForgotPasswordPage(),
          ),
          // Stub destination so we can assert navigation without building the
          // real OTP page (and its dependencies).
          GetPage(
            name: ResetOtpPage.route,
            page: () => const Scaffold(body: Text('otp-page')),
          ),
        ],
      ),
    );
  }

  testWidgets('valid email reaches the datasource and advances to the OTP page',
      (tester) async {
    when(ds.sendPasswordResetOtp(any)).thenAnswer((_) async {});

    await pumpApp(tester);
    await tester.enterText(find.byType(TextFormField), 'user@test.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Reset Code'));
    await tester.pumpAndSettle();

    // Full chain executed down to the mocked datasource…
    verify(ds.sendPasswordResetOtp('user@test.com')).called(1);
    // …and the UI advanced to the next step.
    expect(find.text('otp-page'), findsOneWidget);
  });

  testWidgets('a datasource failure keeps the user on the page',
      (tester) async {
    when(ds.sendPasswordResetOtp(any)).thenThrow(Exception('network down'));

    await pumpApp(tester);
    await tester.enterText(find.byType(TextFormField), 'user@test.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Reset Code'));
    await tester.pump(); // start async
    await tester.pump(const Duration(milliseconds: 600)); // loader + snackbar

    verify(ds.sendPasswordResetOtp('user@test.com')).called(1);
    expect(find.text('otp-page'), findsNothing);
    expect(find.byType(ForgotPasswordPage), findsOneWidget);
    // The repository's friendly error surfaces in a snackbar.
    expect(find.text('Could not send reset code, kindly retry'), findsOneWidget);

    // Drain the snackbar's auto-dismiss timer + exit animation so no ticker or
    // timer is left pending at teardown.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
