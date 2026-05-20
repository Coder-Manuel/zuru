import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_theme.dart';
import 'package:zuru/core/routes/app_pages.dart';
import 'package:zuru/core/services/connectivity_service/offline_widget.dart';
import 'package:zuru/modules/home/presentation/pages/splash_page.dart';

class ZuruApp extends StatelessWidget {
  const ZuruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Zuru World',
      showPerformanceOverlay: kProfileMode,
      navigatorKey: Get.key,
      debugShowCheckedModeBanner: false,
      builder: (_, child) => Stack(children: [child!, const OfflineWidget()]),
      getPages: AppPages.routes,
      initialRoute: SplashPage.route,
      // Default to ClientTheme; ThemeService.applyScoutTheme() is called
      // after auth when the user's role is known.
      theme: ClientTheme.dark,
    );
  }
}
