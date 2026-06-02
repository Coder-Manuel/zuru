import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zuru/core/initializer.dart';
import 'package:zuru/core/services/monitor_service/monitor.service.dart';
import 'package:zuru/zuru_app.dart';

void main() {
  runZonedGuarded(
    () async {
      await Initializer.init();
      runApp(const ZuruApp());
    },
    (Object ex, StackTrace stack) {
      MonitorService.report(ex: ex, stack: stack, library: 'Main ZoneGuard');
    },
  );
}
