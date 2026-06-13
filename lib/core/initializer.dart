import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zuru/config/env.dart';
import 'package:zuru/core/bindings/initial_binding.dart';
import 'package:zuru/core/services/analytics_service/analytics_service.dart';
import 'package:zuru/core/services/monitor_service/monitor.service.dart';
import 'package:zuru/core/services/notification_service/notification_service.dart';
import 'package:zuru/core/services/storage_service/storage.service.dart';
import 'package:zuru/firebase_options.dart';
import 'package:zuru/modules/auth/auth_bindings.dart';
import 'package:zuru/modules/home/home_bindings.dart';
import 'package:zuru/modules/missions/missions_bindings.dart';
import 'package:zuru/modules/payments/payments_bindings.dart';
import 'package:zuru/modules/rating/rating_bindings.dart';
import 'package:zuru/modules/scouts/scouts_bindings.dart';
import 'package:zuru/modules/stream/stream_bindings.dart';
import 'package:zuru/modules/user/user_bindings.dart';

class Initializer {
  static Future<void> _injectServices() async {
    InitialBinding().dependencies();
    AuthBindings().dependencies();
    HomeBindings().dependencies();
    MissionsBindings().dependencies();
    StreamBindings().dependencies();
    UserBindings().dependencies();
    RatingBindings().dependencies();
    PaymentsBindings().dependencies();
    ScoutsBindings().dependencies();
  }

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Env.init();
    await MonitorService.init();
    await NotificationService.init();
    await StorageService.init();
    await AnalyticsService.init();
    await Supabase.initialize(
      url: Env.supabaseURL,
      anonKey: Env.supabaseAnonKey,
    );

    await _injectServices();
  }
}
