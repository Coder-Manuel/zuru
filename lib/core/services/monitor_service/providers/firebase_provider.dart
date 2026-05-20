import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:zuru/config/env.dart';

class FirebaseErrorProvider {
  static FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;

  static Future<bool> report(
    FlutterErrorDetails error, {
    bool isReleaseMode = kReleaseMode,
    bool? isProdEnv,
  }) async {
    bool status = false;

    if (isReleaseMode && (isProdEnv ?? Env.isProd)) {
      final StackTrace safeStack =
          (error.stack == null || error.stack.toString().isEmpty)
              ? StackTrace.current
              : error.stack!;

      final flutterError = FlutterErrorDetails(
        exception: error.exception,
        stack: safeStack,
        library: error.library,
        context: error.context,
        informationCollector: error.informationCollector,
        stackFilter: error.stackFilter,
        silent: error.silent,
      );

      await crashlytics.recordFlutterError(flutterError);
      await crashlytics.sendUnsentReports();
      status = true;
    }

    return status;
  }
}
