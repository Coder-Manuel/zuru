import 'dart:async';

import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/payments/data/models/payments.inputs.dart';
import 'package:zuru/modules/payments/domain/entities/stk_push_result.entity.dart';
import 'package:zuru/modules/payments/domain/repository/payments_repository.dart';

class InitiateStkPushUseCase implements UseCase<StkPushResult, StkPushInput> {
  final PaymentsRepository repo;
  InitiateStkPushUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<StkPushResult>> call(StkPushInput params) =>
      repo.initiateStkPush(params);
}
