import 'dart:async';

import 'package:get/get.dart';

/// The time a dropped connection gets to come back before it counts as gone.
///
/// Used for the other participant dropping and for this device's own
/// connection, so a brief network blip shows a reconnecting overlay instead
/// of ending the stream.
class ReconnectGrace {
  static const period = Duration(seconds: 30);

  /// Seconds left, or null when not counting.
  final secondsLeft = Rx<int?>(null);

  Timer? _timer;

  bool get isRunning => _timer != null;

  /// Starts counting unless already counting; [onExpired] runs once if the
  /// connection is not back in time.
  void start(void Function() onExpired) {
    if (_timer != null) return;
    secondsLeft.value = period.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = (secondsLeft.value ?? 0) - 1;
      if (next > 0) {
        secondsLeft.value = next;
        return;
      }
      cancel();
      onExpired();
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    secondsLeft.value = null;
  }
}
