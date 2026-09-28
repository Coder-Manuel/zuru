import 'dart:async';

import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/payments/data/models/payments.inputs.dart';
import 'package:zuru/modules/payments/domain/entities/collect_payment_result.entity.dart';
import 'package:zuru/modules/payments/domain/repository/payments_repository.dart';

class CollectPaymentUseCase
    implements UseCase<CollectPaymentResult, CollectPaymentInput> {
  final PaymentsRepository repo;
  CollectPaymentUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<CollectPaymentResult>> call(
    CollectPaymentInput params,
  ) => repo.collectPayment(params);
}
