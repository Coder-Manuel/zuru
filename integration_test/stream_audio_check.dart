// On-device checks for BUG-005's audio plumbing: the Bluetooth permission
// round-trip through MainActivity, and headset-preferring routing, without
// crashing when no headset is present (emulators and simulators have none).
//
// On Android 12+ the first test shows the system permission dialog; answer it
// by hand or with adb. To exercise the fresh-grant path (which rebuilds
// flutter_webrtc's AudioSwitch), revoke it first:
//   adb shell pm revoke com.zuru.app android.permission.BLUETOOTH_CONNECT
//
//   fvm flutter test integration_test/stream_audio_check.dart -d <id>

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:zuru/modules/stream/presentation/services/stream_audio.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('asking for Bluetooth access returns and never throws', () async {
    // ignore: avoid_print
    print('QA: requesting Bluetooth access');
    await StreamAudio.ensureBluetoothAccess().timeout(
      const Duration(minutes: 2),
    );
    // ignore: avoid_print
    print('QA: BLUETOOTH_ACCESS_DONE');
  });

  test('routing works with the rebuilt audio switch', () async {
    final outputs = await Hardware.instance.audioOutputs();
    // ignore: avoid_print
    print('QA: audio outputs ${outputs.map((d) => d.label).toList()}');

    await StreamAudio.routeOutput();
    // Twice in a row, as unmuting does.
    await StreamAudio.routeOutput();
  });

  test('device watching only runs on Android and cancels cleanly', () async {
    final sub = StreamAudio.watchDevices();
    expect(sub != null, GetPlatform.isAndroid);

    // A device-list change re-routes; feed one through LiveKit's own stream.
    Hardware.instance.onDeviceChange.add(
      await Hardware.instance.audioOutputs(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));

    await sub?.cancel();
  });
}
