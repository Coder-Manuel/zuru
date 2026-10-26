import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the display awake while the [State] is mounted.
///
/// The OS can drop a wakelock at any time, so it is re-asserted whenever the
/// app resumes. Holders are counted: a page disposed after a newer one opened
/// (e.g. leaving and re-entering a live quickly) can't release it early.
mixin KeepScreenOn<T extends StatefulWidget> on State<T> {
  static int _holders = 0;

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _holders++;
    keepScreenOn();
    _lifecycle = AppLifecycleListener(onResume: keepScreenOn);
  }

  /// Re-asserts the wakelock. Cheap and safe to call often.
  void keepScreenOn() => WakelockPlus.enable().ignore();

  @override
  void dispose() {
    _lifecycle.dispose();
    _holders--;
    if (_holders == 0) WakelockPlus.disable().ignore();
    super.dispose();
  }
}
