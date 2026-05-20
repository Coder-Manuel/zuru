import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/payments/domain/entities/statement.entity.dart';

abstract class PaymentsRepository {
  Future<RepoResponse<List<StatementEntity>>> getStatements();
}
