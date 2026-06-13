/// Canonical route-name constants for the entire application.
///
/// All [Get.toNamed] / [Get.offAllNamed] / [Get.offNamed] call-sites should
/// reference these constants instead of each page's private
/// `static const String route` field.  Keeping every string in one place
/// makes it trivial to audit and refactor the routing graph.
///
/// Routes that serve more than one role (home, stream) are handled by
/// middleware declared in `lib/core/routes/middlewares/`.
abstract final class AppRoutes {
  AppRoutes._();

  // ── Splash ─────────────────────────────────────────────────────────────────
  static const splash = '/';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const login = '/login';
  static const signup = '/signup';
  static const phoneSetup = '/phone-setup';
  static const verify = '/verify';
  static const names = '/names';

  /// Scout-only: bio + tags setup page shown after [names] in the scout
  /// signup flow and on launch when the scout's bio is empty.
  static const scoutAboutMe = '/scout/about-me';

  static const forgotPassword = '/forgot-password';
  static const resetOtp = '/reset-otp';
  static const newPassword = '/new-password';

  // ── Home (role-dispatched) ─────────────────────────────────────────────────
  /// Single canonical entry-point for both roles.
  /// [HomeRoleMiddleware] intercepts this route and redirects scouts to
  /// [scoutHome]; clients are served [HomePage] directly.
  static const home = '/home';

  /// Concrete scout home — navigated to only by [HomeRoleMiddleware].
  /// All code should use [home] instead of this constant.
  static const scoutHome = '/scout/home';

  // ── Missions ──────────────────────────────────────────────────────────────
  static const missionDetails = '/mission-details';
  static const missionComplete = '/mission-complete';
  static const postMission = '/post-mission';
  static const findingScouts = '/finding-scouts';
  static const locationPicker = '/location-picker';
  static const navigation = '/navigation';
  static const gpsVerification = '/gps-verification';

  /// Client-only: "Request a Live" — create a live-request mission for a scout.
  /// Pass the target scout's [Profile] as [Get.arguments].
  static const liveRequest = '/live-request';

  /// Client-only: live-request confirmation screen.
  static const requestSent = '/request-sent';

  // ── Stream (role-dispatched) ──────────────────────────────────────────────
  /// Single canonical entry-point for live-stream sessions.
  /// [StreamRoleMiddleware] swaps the rendered widget based on role:
  ///   - Scout  → [StreamPage]     (live broadcast)
  ///   - Client → [JoinStreamPage] (viewer)
  /// Pass the active [MissionEntity] as [Get.arguments].
  static const stream = '/stream';

  // ── Rating ────────────────────────────────────────────────────────────────
  static const rateScout = '/rate-scout';
  static const rateClient = '/rate-client';

  // ── Payments ──────────────────────────────────────────────────────────────
  static const statements = '/statements';

  // ── User / Profile ────────────────────────────────────────────────────────
  static const profile = '/profile';

  /// Scout-only World Profile editor. Guarded by [ScoutOnlyMiddleware].
  static const scoutProfileEdit = '/scout/profile/edit';

  // ── Scouts (client) ─────────────────────────────────────────────────────────
  /// Client-only scout profile detail. Pass the scout's profile id as
  /// [Get.arguments]. Guarded by [ClientOnlyMiddleware].
  static const scoutDetail = '/scouts/detail';
}
