import 'package:get/get.dart';
import 'package:zuru/core/routes/app_route.dart';
import 'package:zuru/core/routes/middlewares/scout_only_middleware.dart';
import 'package:zuru/modules/auth/presentation/pages/forgot_password_page.dart';
import 'package:zuru/modules/auth/presentation/pages/login_page.dart';
import 'package:zuru/modules/auth/presentation/pages/names_setup_page.dart';
import 'package:zuru/modules/auth/presentation/pages/new_password_page.dart';
import 'package:zuru/modules/auth/presentation/pages/phone_setup_page.dart';
import 'package:zuru/modules/auth/presentation/pages/reset_otp_page.dart';
import 'package:zuru/modules/auth/presentation/pages/scout_about_me_page.dart';
import 'package:zuru/modules/auth/presentation/pages/signup_page.dart';
import 'package:zuru/modules/auth/presentation/pages/verify_page.dart';

class AuthRoutes implements AppRoute {
  @override
  List<GetPage> pages = [
    GetPage(name: LoginPage.route, page: () => const LoginPage()),
    GetPage(name: SignupPage.route, page: () => const SignupPage()),
    GetPage(name: PhoneSetupPage.route, page: () => const PhoneSetupPage()),
    GetPage(name: VerifyPage.route, page: () => const VerifyPage()),
    GetPage(name: NamesSetupPage.route, page: () => const NamesSetupPage()),

    // ── Scout-only onboarding ─────────────────────────────────────────────────
    GetPage(
      name: ScoutAboutMePage.route,
      page: () => const ScoutAboutMePage(),
      middlewares: [ScoutOnlyMiddleware()],
    ),

    // ── Password reset ────────────────────────────────────────────────────────
    GetPage(
      name: ForgotPasswordPage.route,
      page: () => const ForgotPasswordPage(),
    ),
    GetPage(name: ResetOtpPage.route, page: () => const ResetOtpPage()),
    GetPage(name: NewPasswordPage.route, page: () => const NewPasswordPage()),
  ];
}
