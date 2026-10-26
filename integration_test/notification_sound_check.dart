// On-device check for BUG-001's foreground sound: on Android, a push that
// arrives while the app is open plays its channel's sound (FCM shows nothing
// itself). Run it while watching the audio players:
//   adb shell dumpsys audio | grep -A3 "USAGE_NOTIFICATION"
//
//   fvm flutter test integration_test/notification_sound_check.dart -d <id>
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zuru/core/services/notification_service/notification_service.dart';

RemoteMessage _push(String? channelId) => RemoteMessage(
  data: const {'type': 'SCOUT_LIVE'},
  notification: RemoteNotification(
    title: 'Your guide is live',
    android: AndroidNotification(channelId: channelId),
  ),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final channel in ['live_alerts', 'mission_updates', null]) {
    test('plays the sound for channel $channel and never throws', () async {
      await NotificationService.playForegroundAlert(_push(channel));
      // ignore: avoid_print
      print('QA: PLAYED $channel');
      // Window to inspect the audio players.
      await Future<void>.delayed(const Duration(seconds: 4));
    });
  }
}
