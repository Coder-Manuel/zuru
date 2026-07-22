import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/payments/data/models/payments.inputs.dart';
import 'package:zuru/modules/payments/domain/entities/payment.entity.dart';
import 'package:zuru/modules/payments/domain/entities/statement.entity.dart';
import 'package:zuru/modules/payments/domain/entities/stk_push_result.entity.dart';

abstract class PaymentsRepository {
  Future<RepoResponse<List<StatementEntity>>> getStatements();

  /// Triggers an M-Pesa STK push for the given mission.
  Future<RepoResponse<StkPushResult>> initiateStkPush(StkPushInput input);

  /// Live stream of a payment row's state, keyed by its id.
  Stream<RepoResponse<PaymentEntity>> watchPayment(String paymentId);
}
