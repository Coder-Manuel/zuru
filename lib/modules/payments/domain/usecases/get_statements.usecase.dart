import 'dart:async';

import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/payments/domain/entities/statement.entity.dart';
import 'package:zuru/modules/payments/domain/repository/payments_repository.dart';

class GetStatementsUseCase implements UseCase<List<StatementEntity>, dynamic> {
  final PaymentsRepository repo;
  GetStatementsUseCase({required this.repo});

  @override
  FutureOr<RepoResponse<List<StatementEntity>>> call([_]) =>
      repo.getStatements();
}
