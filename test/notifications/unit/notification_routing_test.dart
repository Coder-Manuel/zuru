// Unit tests for how a push is read and what it opens. The type alone decides
// the role and the action; the push carries no route.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/modules/notifications/data/models/notification_payload.dart';
import 'package:zuru/modules/notifications/data/models/notification_type.dart';
import 'package:zuru/modules/notifications/data/repositories_impl/notifications_repository_impl.dart';

import '../../helpers/test_mocks.mocks.dart';

void main() {
  setUpAll(() => Get.testMode = true);

  group('NotificationType', () {
    test('parses every type the backend sends', () {
      const backend = [
        'LIVE_REQUEST_CREATED',
        'MISSION_REQUEST_PAID',
        'REQUEST_CANCELLED',
        'MISSION_ACCEPTED',
        'MISSION_ENROUTE',
        'SCOUT_LIVE',
        'MISSION_DECLINED',
        'MISSION_RELEASED',
        'PAYMENT_EXPIRED',
      ];
      expect(backend.map(NotificationType.fromApi), everyElement(isNotNull));
      expect(NotificationType.fromApi('SOMETHING_NEW'), isNull);
      expect(NotificationType.fromApi(null), isNull);
    });

    test('scout types belong to the scout role', () {
      expect(
        [
          NotificationType.liveRequestCreated,
          NotificationType.missionRequestPaid,
          NotificationType.requestCancelled,
        ].map((t) => t.role),
        everyElement(UserRole.scout),
      );
    });

    test('client types belong to the client role', () {
      expect(
        [
          NotificationType.missionAccepted,
          NotificationType.missionEnroute,
          NotificationType.scoutLive,
          NotificationType.missionDeclined,
          NotificationType.missionReleased,
          NotificationType.paymentExpired,
        ].map((t) => t.role),
        everyElement(UserRole.client),
      );
    });

    test('each type opens the right place', () {
      expect(
        {for (final t in NotificationType.values) t: t.action},
        {
          NotificationType.liveRequestCreated: NotificationAction.radar,
          NotificationType.missionRequestPaid: NotificationAction.radar,
          NotificationType.requestCancelled: NotificationAction.tasks,
          NotificationType.missionAccepted: NotificationAction.payForMission,
          NotificationType.missionEnroute: NotificationAction.map,
          NotificationType.scoutLive: NotificationAction.joinLive,
          NotificationType.missionDeclined: NotificationAction.liveChecks,
          NotificationType.missionReleased: NotificationAction.liveChecks,
          NotificationType.paymentExpired: NotificationAction.liveChecks,
        },
      );
    });
  });

  group('NotificationPayload.fromData', () {
    test('reads the type, ids and wording', () {
      final payload = NotificationPayload.fromData(
        {'type': 'SCOUT_LIVE', 'mission_id': 'm1', 'notification_id': 'n1'},
        title: 'Brian is live, join now',
        body: 'Your live has started.',
      )!;

      expect(payload.type, NotificationType.scoutLive);
      expect(payload.missionId, 'm1');
      expect(payload.notificationId, 'n1');
      expect(payload.title, 'Brian is live, join now');
    });

    test('ignores a type this build does not know', () {
      expect(NotificationPayload.fromData({'type': 'NEW_THING'}), isNull);
      expect(NotificationPayload.fromData({}), isNull);
    });

    test('treats empty ids as missing', () {
      final payload = NotificationPayload.fromData({
        'type': 'MISSION_ENROUTE',
        'mission_id': '',
      })!;
      expect(payload.missionId, isNull);
      expect(payload.notificationId, isNull);
    });

    test('knows when an accepted request still needs paying', () {
      final unpaid = NotificationPayload.fromData({
        'type': 'MISSION_ACCEPTED',
        'payment_window_min': '30',
      })!;
      final pool = NotificationPayload.fromData({'type': 'MISSION_ACCEPTED'})!;

      expect(unpaid.awaitsPayment, isTrue);
      expect(pool.awaitsPayment, isFalse);
    });
  });

  group('NotificationsRepositoryImpl.markRead', () {
    late MockRemoteNotificationsDatasource ds;
    late NotificationsRepositoryImpl repo;

    setUp(() {
      ds = MockRemoteNotificationsDatasource();
      repo = NotificationsRepositoryImpl(remoteDatasource: ds);
    });

    test('marks the row read', () async {
      when(ds.markRead('n1')).thenAnswer((_) async {});

      expect((await repo.markRead('n1')).isRight(), isTrue);
      verify(ds.markRead('n1')).called(1);
    });

    test('fails when the datasource throws', () async {
      when(ds.markRead(any)).thenThrow(Exception('boom'));

      final result = await repo.markRead('n1');

      expect(
        result.fold((l) => l.message, (_) => null),
        'Could not update the notification.',
      );
    });
  });
}
