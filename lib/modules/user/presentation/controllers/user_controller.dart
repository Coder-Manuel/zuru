import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/routes/app_routes.dart';
import 'package:zuru/core/services/notification_service/notification_service.dart';
import 'package:zuru/core/services/role_service/role_service.dart';
import 'package:zuru/core/utils/loader.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/auth/domain/usecases/logout.usecase.dart';
import 'package:zuru/modules/auth/presentation/pages/login_page.dart';
import 'package:zuru/modules/user/domain/usecases/get_user_info.usecase.dart';
import 'package:zuru/modules/user/domain/usecases/update_fcm_token.usecase.dart';

class UserController extends GetxController {
  final _getUserInfoUsecase = Get.find<GetUserInfoUseCase>();
  final _updateFcmTokenUseCase = Get.find<UpdateFcmTokenUseCase>();
  final _logoutUseCase = Get.find<LogoutUseCase>();

  Rx<User?> currentUser = Rx<User?>(null);

  // ── Settings toggles ──────────────────────────────────────────────────────
  final RxBool biometricsEnabled = true.obs;
  final RxBool notificationsEnabled = true.obs;

  /// Periodic retry timer — active only while the FCM token is still null.
  Timer? _fcmRetryTimer;

  /// Maximum number of retry ticks before giving up on FCM token sync.
  static const _fcmMaxRetries = 5;
  int _fcmRetryCount = 0;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onClose() {
    _cancelFcmRetry();
    super.onClose();
  }

  // ── Public ────────────────────────────────────────────────────────────────

  Future<void> getUserDetails() async {
    final response = await _getUserInfoUsecase();

    response.fold((_) => null, (data) {
      currentUser.value = data;
      RoleService.instance.setRole(data.defaultRole);
      _syncFcmToken();
    });
  }

  /// Inspects [user]'s profile completeness for the currently active role and
  /// returns the next [AppRoutes] destination.
  ///
  /// Decision order:
  /// 1. Scout with no phone → [AppRoutes.phoneSetup]
  /// 2. Profile for active role missing, or names empty, or status inactive
  ///    → [AppRoutes.names]
  /// 3. Scout with no bio → [AppRoutes.scoutAboutMe]
  /// 4. All complete → [AppRoutes.home]  (middleware handles client/scout split)
  String resolvePostAuthDestination(User user) {
    final role = RoleService.instance.role.value;

    // 1. Scouts must have a phone number.
    if (role == UserRole.scout && (user.phone == null || user.phone!.isEmpty)) {
      return AppRoutes.phoneSetup;
    }

    // 2. Locate the profile matching the active role.
    final profile = user.profiles.where((p) => p.role == role).firstOrNull;

    if (profile == null ||
        (profile.lastName?.isEmpty ?? true) ||
        profile.status != UserStatus.active) {
      return AppRoutes.names;
    }

    // 3. Scout must have completed their "About Me".
    if (role == UserRole.scout && (profile.bio?.isEmpty ?? true)) {
      return AppRoutes.scoutAboutMe;
    }

    return AppRoutes.home;
  }

  Future<void> logout() async {
    Loader.show(message: 'Login out...');
    final response = await _logoutUseCase();
    Loader.dismiss();

    response.fold(
      (ex) {
        Toast.error(ex.message);
      },
      (_) {
        Get.offAllNamed(LoginPage.route);
      },
    );
  }

  // ── Private ───────────────────────────────────────────────────────────────

  /// Attempts to push the FCM token to Supabase.
  /// If the token is not yet available, starts a 5-second retry timer that
  /// pings [NotificationService.fetchToken] on every tick until the token
  /// is obtained and synced — or the controller is disposed.
  Future<void> _syncFcmToken() async {
    final token = NotificationService.fcmToken;

    if (token == null) {
      log(
        'FCM token not available — starting retry timer',
        name: 'UserController',
      );
      return _startFcmRetryTimer();
    }

    // Skip if the token hasn't changed since the last sync.
    if (currentUser.value?.fcmToken == token) {
      log('FCM token unchanged, skipping sync', name: 'UserController');
      return;
    }

    await _pushFcmToken(token);
  }

  /// Pushes [token] to Supabase via the use-case.
  Future<void> _pushFcmToken(String token) async {
    final response = await _updateFcmTokenUseCase(token);
    response.fold(
      (err) =>
          log('FCM token sync failed: ${err.message}', name: 'UserController'),
      (_) {
        log('FCM token synced', name: 'UserController');
        _cancelFcmRetry();
      },
    );
  }

  /// Starts a periodic timer that re-pings [NotificationService.fetchToken]
  /// every 5 seconds. Stops automatically after [_fcmMaxRetries] ticks or
  /// once a token is successfully synced — whichever comes first.
  void _startFcmRetryTimer() {
    // Guard: don't stack multiple timers if called again before one resolves.
    if (_fcmRetryTimer?.isActive ?? false) return;

    _fcmRetryCount = 0;

    _fcmRetryTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      _fcmRetryCount++;

      log(
        'FCM retry tick $_fcmRetryCount/$_fcmMaxRetries — pinging NotificationService…',
        name: 'UserController',
      );

      if (_fcmRetryCount >= _fcmMaxRetries) {
        log(
          'FCM token not obtained after $_fcmMaxRetries attempts — giving up',
          name: 'UserController',
        );
        _cancelFcmRetry();
        return;
      }

      final token = await NotificationService.fetchToken();

      if (token == null) {
        log('FCM token still null, will retry…', name: 'UserController');
        return;
      }

      // Token arrived — skip if unchanged, otherwise sync and stop the timer.
      if (currentUser.value?.fcmToken == token) {
        log('FCM token unchanged, stopping retry', name: 'UserController');
        return _cancelFcmRetry();
      }

      await _pushFcmToken(token);
    });
  }

  void _cancelFcmRetry() {
    _fcmRetryTimer?.cancel();
    _fcmRetryTimer = null;
    _fcmRetryCount = 0;
  }
}
