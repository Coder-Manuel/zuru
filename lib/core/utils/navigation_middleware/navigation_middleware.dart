import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/core/services/analytics_service/analytics_service.dart';
import 'package:zuru/core/utils/navigation_middleware/navigation_controller.dart';

class NavigatorMiddleware<R extends Route<dynamic>>
    extends RouteObserver<Route> {
  NavigatorMiddleware();

  final navigationCTRL = Get.find<NavigationController>();
  final AnalyticsService analytics = AnalyticsService.instance;

  @override
  void didPush(Route route, Route? previousRoute) {
    navigationCTRL.push(route.settings.name);
    analytics.trackScreenView(
      currentScreen: route.settings.name,
      previousScreen: previousRoute?.settings.name,
    );
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    navigationCTRL.remove(route.settings.name);
    analytics.trackScreenView(
      currentScreen: previousRoute?.settings.name,
      previousScreen: route.settings.name,
    );
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    navigationCTRL.replace(
      oldRoute: oldRoute?.settings.name,
      newRoute: newRoute?.settings.name,
    );
    analytics.trackScreenView(
      currentScreen: newRoute?.settings.name,
      previousScreen: oldRoute?.settings.name,
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    navigationCTRL.remove(route.settings.name);
    super.didRemove(route, previousRoute);
  }
}
