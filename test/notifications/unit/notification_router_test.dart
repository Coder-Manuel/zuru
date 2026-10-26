// Unit tests for when NotificationRouter acts on a tap (BUG-001).
//
// A tap that arrives before the user is home is parked and opened once they
// get there. The router must not lose that state to GetX's stale route
// reports when popups close. Pushes come from a fake stream; MISSION_DECLINED
// is used because it only switches the home tab, which is easy to observe.
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/routes/app_routes.dart';
import 'package:zuru/modules/home/presentation/controllers/home_controller.dart';
import 'package:zuru/modules/missions/domain/usecases/get_mission_by_id.usecase.dart';
import 'package:zuru/modules/notifications/data/repositories_impl/notifications_repository_impl.dart';
import 'package:zuru/modules/notifications/domain/usecases/mark_notification_read.usecase.dart';
import 'package:zuru/modules/notifications/presentation/services/notification_router.dart';

import '../../helpers/test_mocks.mocks.dart';

/// Opens the Viewer's Live Checks tab (index 1).
const _declined = RemoteMessage(
  data: {'type': 'MISSION_DECLINED', 'mission_id': 'm1'},
);

Routing _page(String name) => Routing(
  current: name,
  route: MaterialPageRoute<void>(builder: (_) => const SizedBox()),
);

/// What GetX reports when a popup closes over another popup: a stale name
/// and a popup route.
Routing _popupClosed(String staleName) => Routing(
  current: staleName,
  route: RawDialogRoute<void>(pageBuilder: (_, _, _) => const SizedBox()),
);

void main() {
  late StreamController<RemoteMessage> taps;
  late HomeController home;
  late NotificationRouter router;

  setUp(() => Get.testMode = true);

  tearDown(() async {
    await taps.close();
    Get.reset();
  });

  /// Built inside each test, so the fake stream delivers within the test's
  /// fake-async zone.
  void startRouter() {
    taps = StreamController<RemoteMessage>();
    home = Get.put(HomeController());
    Get.put(GetMissionByIdUseCase(repo: MockMissionsRepository()));
    Get.put(
      MarkNotificationReadUseCase(
        repo: NotificationsRepositoryImpl(
          remoteDatasource: MockRemoteNotificationsDatasource(),
        ),
      ),
    );
    router = Get.put(
      NotificationRouter(
        openedMessages: taps.stream,
        foregroundMessages: const Stream.empty(),
        initialMessage: () async => null,
        isSignedIn: () => true,
        currentRole: () => UserRole.client,
      ),
    );
  }

  /// Home is on screen, so the router's own navigation stays put.
  Future<void> pumpHome(WidgetTester tester) async {
    startRouter();
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.home,
        getPages: [GetPage(name: AppRoutes.home, page: () => const Scaffold())],
      ),
    );
    await tester.pump();
  }

  Future<void> tap(WidgetTester tester) async {
    taps.add(_declined);
    await tester.pump();
  }

  testWidgets('a tap before home waits, then opens once home is reached', (
    tester,
  ) async {
    await pumpHome(tester);

    await tap(tester);
    expect(home.currentIndex.value, 0, reason: 'parked until home');

    router.onRouteChanged(_page(AppRoutes.home));
    await tester.pump();

    expect(home.currentIndex.value, 1);
  });

  testWidgets('a popup closing over a popup does not drop later taps', (
    tester,
  ) async {
    await pumpHome(tester);
    router.onRouteChanged(_page(AppRoutes.home));

    // Right after signing in, GetX's "previous" route is /login.
    router.onRouteChanged(_popupClosed(AppRoutes.login));
    await tap(tester);

    expect(home.currentIndex.value, 1);
  });

  testWidgets('signing out parks taps until the user is home again', (
    tester,
  ) async {
    await pumpHome(tester);
    router.onRouteChanged(_page(AppRoutes.home));

    router.onRouteChanged(_page(AppRoutes.login));
    await tap(tester);
    expect(home.currentIndex.value, 0);

    router.onRouteChanged(_page(AppRoutes.home));
    await tester.pump();
    expect(home.currentIndex.value, 1);
  });

  testWidgets('signing out drops a tap that was still waiting', (tester) async {
    await pumpHome(tester);

    await tap(tester);
    router.onRouteChanged(_page(AppRoutes.login));
    router.onRouteChanged(_page(AppRoutes.home));
    await tester.pump();

    expect(home.currentIndex.value, 0);
  });

  testWidgets('a push of an unknown type is ignored', (tester) async {
    await pumpHome(tester);
    router.onRouteChanged(_page(AppRoutes.home));

    taps.add(const RemoteMessage(data: {'type': 'SOMETHING_NEW'}));
    await tester.pump();

    expect(home.currentIndex.value, 0);
  });
}
