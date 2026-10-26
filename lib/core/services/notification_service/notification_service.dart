import 'dart:async';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:zuru/core/utils/error_wrapper.dart';

class NotificationService {
  NotificationService._();

  static const _library = 'NotificationService';
  static final _messaging = FirebaseMessaging.instance;

  /// Must match MainActivity's channel name.
  static const _androidChannel = MethodChannel('com.zuru.app/notifications');

  static String? fcmToken;

  static final _tokenRefreshes = StreamController<String>.broadcast();

  /// Emits whenever Firebase rotates the token, so it can be saved again.
  static Stream<String> get tokenRefreshes => _tokenRefreshes.stream;

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

        // iOS: play the sound for pushes that arrive while the app is open.
        // No banner; the app shows its own toast or dialog.
        await _messaging.setForegroundNotificationPresentationOptions(
          sound: true,
        );

        if (GetPlatform.isIOS) await _messaging.getAPNSToken();

        fcmToken = await _messaging.getToken();

        log(
          fcmToken != null ? 'FCM token obtained' : 'FCM token unavailable',
          name: _library,
        );

        _messaging.onTokenRefresh.listen((newToken) {
          fcmToken = newToken;
          _tokenRefreshes.add(newToken);
          log('FCM token refreshed', name: _library);
        });
      },
      library: _library,
      description: 'while initialising notification service',
    );
  }

  /// Pushes received while the app is open.
  static Stream<RemoteMessage> get foregroundMessages =>
      FirebaseMessaging.onMessage;

  /// Taps on a push while the app was in the background.
  static Stream<RemoteMessage> get openedMessages =>
      FirebaseMessaging.onMessageOpenedApp;

  /// The push whose tap launched the app, if any. Firebase returns it once.
  static Future<RemoteMessage?> initialMessage() =>
      ErrorWrapper.async<RemoteMessage?>(
        _messaging.getInitialMessage,
        library: _library,
        description: 'while reading the launch notification',
      );

  /// Android: FCM shows nothing for a push while the app is open, so play
  /// its channel's sound (the native side honours the user's channel
  /// settings and Do Not Disturb). iOS handles this through the presentation
  /// options set in [init].
  static Future<void> playForegroundAlert(RemoteMessage message) async {
    if (!GetPlatform.isAndroid) return;
    await ErrorWrapper.async<void>(
      () => _androidChannel.invokeMethod<void>('playAlert', {
        'channelId': message.notification?.android?.channelId,
      }),
      library: _library,
      description: 'while playing the foreground notification sound',
    );
  }

  /// Asks for permission again (e.g. when the user turns notifications back
  /// on). False when the user has denied it at the OS level.
  static Future<bool> requestPermission() async {
    final settings = await ErrorWrapper.async<NotificationSettings>(
      () => _messaging.requestPermission(alert: true, badge: true, sound: true),
      library: _library,
      description: 'while requesting notification permission',
    );
    final status = settings?.authorizationStatus;
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
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
