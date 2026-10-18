// Unit tests for the in-app notification list's data path: row parsing and
// the repository over a mocked datasource.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:zuru/modules/notifications/data/models/app_notification.model.dart';
import 'package:zuru/modules/notifications/data/models/notification_type.dart';
import 'package:zuru/modules/notifications/data/repositories_impl/notifications_repository_impl.dart';

import '../../helpers/test_mocks.mocks.dart';

Map<String, dynamic> row({
  String id = 'n1',
  String type = 'MISSION_ACCEPTED',
  String? readAt,
}) => {
  'id': id,
  'type': type,
  'mission_id': 'm1',
  'title': 'Request accepted',
  'body': 'Brian accepted your live check.',
  'read_at': readAt,
  'created_at': '2026-10-19T08:00:00Z',
};

void main() {
  setUpAll(() => Get.testMode = true);

  group('AppNotificationModel.fromMap', () {
    test('reads a row', () {
      final n = AppNotificationModel.fromMap(row());

      expect(n.id, 'n1');
      expect(n.type, NotificationType.missionAccepted);
      expect(n.missionId, 'm1');
      expect(n.title, 'Request accepted');
      expect(n.isRead, isFalse);
    });

    test('is read once read_at is set', () {
      expect(
        AppNotificationModel.fromMap(
          row(readAt: '2026-10-19T09:00:00Z'),
        ).isRead,
        isTrue,
      );
    });

    test('keeps a row of an unknown type, with no type', () {
      final n = AppNotificationModel.fromMap(row(type: 'SOMETHING_NEW'));
      expect(n.type, isNull);
      expect(n.title, 'Request accepted');
    });
  });

  group('NotificationsRepositoryImpl', () {
    late MockRemoteNotificationsDatasource ds;
    late NotificationsRepositoryImpl repo;

    setUp(() {
      ds = MockRemoteNotificationsDatasource();
      repo = NotificationsRepositoryImpl(remoteDatasource: ds);
    });

    test('watch maps each emission into entities', () async {
      final source = StreamController<List<Map<String, dynamic>>>();
      when(ds.watch('p1')).thenAnswer((_) => source.stream);

      final first = repo.watch('p1').first;
      source.add([
        row(id: 'n1'),
        row(id: 'n2', readAt: '2026-10-19T09:00:00Z'),
      ]);

      final items = (await first).getOrElse(() => []);
      expect(items.map((n) => n.id), ['n1', 'n2']);
      expect(items.map((n) => n.isRead), [false, true]);
      await source.close();
    });

    test('markAllRead marks the profile\'s notifications read', () async {
      when(ds.markAllRead('p1')).thenAnswer((_) async {});

      expect((await repo.markAllRead('p1')).isRight(), isTrue);
      verify(ds.markAllRead('p1')).called(1);
    });

    test('markAllRead fails when the datasource throws', () async {
      when(ds.markAllRead(any)).thenThrow(Exception('boom'));

      final result = await repo.markAllRead('p1');

      expect(
        result.fold((l) => l.message, (_) => null),
        'Could not update the notification.',
      );
    });
  });
}
