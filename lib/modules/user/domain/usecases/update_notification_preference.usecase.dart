import 'dart:async';

import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/user/data/models/notification_preference.input.dart';
import 'package:zuru/modules/user/domain/repository/user_repository.dart';

class UpdateNotificationPreferenceUseCase
    implements UseCase<void, NotificationPreferenceInput> {
  final UserRepository repo;
  UpdateNotificationPreferenceUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<void>> call(NotificationPreferenceInput input) {
    return repo.updateNotificationPreference(input);
  }
}
