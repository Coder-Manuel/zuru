import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:zuru/core/utils/error_wrapper.dart';

class NotificationService {
  NotificationService._();

  static const _library = 'NotificationService';
  static final _messaging = FirebaseMessaging.instance;

  static String? fcmToken;

  static Future<void> init() async {
    await ErrorWrapper.async<void>(
      () async {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        log(
          'Notification permission: ${settings.authorizationStatus}',
          name: _library,
        );

        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          log(
            'Notification permission denied — skipping token fetch',
            name: _library,
          );
          return;
        }

        if (GetPlatform.isIOS) await _messaging.getAPNSToken();

        fcmToken = await _messaging.getToken();

        log(
          fcmToken != null ? 'FCM token obtained' : 'FCM token unavailable',
          name: _library,
        );

        _messaging.onTokenRefresh.listen((newToken) {
          fcmToken = newToken;
          log('FCM token refreshed', name: _library);
        });
      },
      library: _library,
      description: 'while initialising notification service',
    );
  }

  static Future<String?> fetchToken() async {
    await ErrorWrapper.async<void>(
      () async {
        if (fcmToken != null) return;
        if (GetPlatform.isIOS) await _messaging.getAPNSToken();
        fcmToken = await _messaging.getToken();
        log(
          fcmToken != null
              ? 'FCM token obtained on retry'
              : 'FCM token still unavailable',
          name: _library,
        );
      },
      library: _library,
      description: 'while retrying FCM token fetch',
    );
    return fcmToken;
  }
}
