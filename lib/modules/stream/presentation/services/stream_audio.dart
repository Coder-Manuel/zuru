import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';

/// Audio routing for live streams: the loudspeaker by default, but a
/// connected Bluetooth or wired headset always takes over.
class StreamAudio {
  StreamAudio._();

  static const _channel = MethodChannel('com.zuru.app/audio');

  /// Android 12+ only lists Bluetooth headsets once BLUETOOTH_CONNECT is
  /// granted. Call before connecting to the room. Never throws.
  static Future<void> ensureBluetoothAccess() async {
    if (!GetPlatform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('ensureBluetoothPermission');
    } catch (_) {}
  }

  /// Must be called AFTER the WebRTC audio unit is fully negotiated.
  static Future<void> routeOutput() async {
    try {
      if (GetPlatform.isAndroid) {
        // Hardware.setSpeakerphoneOn(true) selects the speaker on Android
        // even when a headset is connected.
        await rtc.Helper.setSpeakerphoneOnButPreferBluetooth();
      } else {
        // On iOS this only adds `defaultToSpeaker`, which keeps the
        // loudspeaker over the earpiece while headsets still win.
        await Hardware.instance.setSpeakerphoneOn(
          true,
          forceSpeakerOutput: true,
        );
      }
    } catch (_) {}
  }

  /// Re-routes when a headset is connected or disconnected mid-stream.
  /// iOS follows headsets on its own, so this only listens on Android.
  static StreamSubscription<List<MediaDevice>>? watchDevices() {
    if (!GetPlatform.isAndroid) return null;

    String? lastSeen;
    return Hardware.instance.onDeviceChange.stream.listen((devices) {
      // Our own re-route also emits; only react to a real device change.
      final ids = [
        for (final d in devices)
          if (d.kind == 'audiooutput' || d.kind == 'audioinput') d.deviceId,
      ]..sort();
      final seen = ids.join(',');
      if (seen == lastSeen) return;
      lastSeen = seen;
      routeOutput();
    });
  }
}
