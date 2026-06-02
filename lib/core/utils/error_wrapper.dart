import 'dart:async';

import 'package:zuru/core/services/monitor_service/monitor.service.dart';

class ErrorWrapper {
  @pragma('vm:notify-debugger-on-exception')
  static T? sync<T>(
    T Function() callback, {
    required String library,
    required String description,
    T? Function(Object error)? onError,
  }) {
    try {
      return callback();
    } catch (error, stack) {
      MonitorService.report(
        ex: error,
        library: library,
        description: description,
        stack: stack,
      );
      if (onError != null) return onError(error);
      return null;
    }
  }

  @pragma('vm:notify-debugger-on-exception')
  static Future<T?> async<T>(
    Future<T> Function() callback, {
    required String library,
    required String description,
    T? Function(Object error)? onError,
  }) async {
    try {
      return await callback();
    } catch (error, stack) {
      MonitorService.report(
        ex: error,
        library: library,
        description: description,
        stack: stack,
      );
      if (onError != null) return onError(error);
      return null;
    }
  }

  @pragma('vm:notify-debugger-on-exception')
  static Stream<T> stream<T>(
    Stream<T> Function() callback, {
    required String library,
    required String description,
    T Function(Object error)? onError,
  }) async* {
    try {
      yield* callback();
    } catch (error, stack) {
      MonitorService.report(
        ex: error,
        library: library,
        description: description,
        stack: stack,
      );
      if (onError != null) {
        yield onError(error);
        return;
      }
      rethrow;
    }
  }
}
