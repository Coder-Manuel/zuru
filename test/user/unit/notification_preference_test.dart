// Unit tests for the push notification setting: how it is read from `me()`,
// saved by the repository, and passed through the use case.
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:zuru/core/models/user.model.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/user/data/models/notification_preference.input.dart';
import 'package:zuru/modules/user/data/repositories_impl/user_repository_impl.dart';
import 'package:zuru/modules/user/domain/usecases/update_notification_preference.usecase.dart';

import '../../helpers/test_mocks.mocks.dart';

void main() {
  setUpAll(() => Get.testMode = true);

  group('UserModel.notificationsEnabled', () {
    test('reads false from me()', () {
      final user = UserModel.fromMap({
        'id': 'u1',
        'notifications_enabled': false,
      });
      expect(user.notificationsEnabled, isFalse);
    });

    test('defaults to true when the field is missing', () {
      expect(UserModel.fromMap({'id': 'u1'}).notificationsEnabled, isTrue);
    });
  });

  group('UserRepositoryImpl.updateNotificationPreference', () {
    late MockRemoteUserDatasource ds;
    late UserRepositoryImpl repo;

    setUp(() {
      ds = MockRemoteUserDatasource();
      repo = UserRepositoryImpl(remoteDatasource: ds);
      when(
        ds.updateNotificationPreference(
          enabled: anyNamed('enabled'),
          token: anyNamed('token'),
        ),
      ).thenAnswer((_) async {});
    });

    test('turning on saves the token', () async {
      final result = await repo.updateNotificationPreference(
        const NotificationPreferenceInput(enabled: true, token: 'tok'),
      );

      expect(result.isRight(), isTrue);
      verify(
        ds.updateNotificationPreference(enabled: true, token: 'tok'),
      ).called(1);
    });

    test('turning off always clears the token', () async {
      await repo.updateNotificationPreference(
        const NotificationPreferenceInput(enabled: false, token: 'tok'),
      );

      verify(
        ds.updateNotificationPreference(enabled: false, token: null),
      ).called(1);
    });

    test('fails when the datasource throws', () async {
      when(
        ds.updateNotificationPreference(
          enabled: anyNamed('enabled'),
          token: anyNamed('token'),
        ),
      ).thenThrow(Exception('boom'));

      final result = await repo.updateNotificationPreference(
        const NotificationPreferenceInput(enabled: false),
      );

      expect(
        result.fold((l) => l.message, (_) => null),
        'Failed to update notification settings',
      );
    });
  });

  group('UpdateNotificationPreferenceUseCase', () {
    test('passes the input to the repository', () async {
      final repo = MockUserRepository();
      const input = NotificationPreferenceInput(enabled: false);
      when(
        repo.updateNotificationPreference(input),
      ).thenAnswer((_) async => Right<ApiFail, void>(null));

      final result = await UpdateNotificationPreferenceUseCase(repo: repo)(
        input,
      );

      expect(result.isRight(), isTrue);
      verify(repo.updateNotificationPreference(input)).called(1);
    });
  });
}
