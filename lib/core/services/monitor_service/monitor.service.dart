import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:zuru/config/env.dart';
import 'package:zuru/core/services/monitor_service/providers/firebase_provider.dart';

class MonitorService {
  static Future<void> init() async {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      FirebaseErrorProvider.report(
        details,
        isReleaseMode: Get.testMode || kReleaseMode,
        isProdEnv: Get.testMode || Env.isProd,
      );
      FlutterError.resetErrorCount();
    };
    log('Monitor Service Initialized');
  }

  /// Records a step of a flow that can fail without an error (a notification
  /// tap that opens nothing, say). Printed in debug builds and attached to the
  /// next Crashlytics report.
  static void breadcrumb(String message, {required String library}) {
    log(message, name: library);
    if (Get.testMode) return;
    if (kDebugMode) debugPrint('[$library] $message');
    FirebaseErrorProvider.crashlytics.log('[$library] $message').ignore();
  }

  static void report({
    required Object ex,
    required String library,
    StackTrace? stack,
    String? description,
  }) {
    if (Get.testMode) return;
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: ex,
        stack: stack,
        library: library,
        context: description != null ? ErrorDescription(description) : null,
      ),
    );
  }
}
