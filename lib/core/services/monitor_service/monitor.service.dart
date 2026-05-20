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
