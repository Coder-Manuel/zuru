import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/payments/data/models/payments.inputs.dart';
import 'package:zuru/modules/payments/domain/entities/collect_payment_result.entity.dart';
import 'package:zuru/modules/payments/domain/entities/payment.entity.dart';
import 'package:zuru/modules/payments/domain/entities/statement.entity.dart';

abstract class PaymentsRepository {
  Future<RepoResponse<List<StatementEntity>>> getStatements();

  /// Starts an IntaSend collection (M-Pesa STK push or card checkout) for the
  /// given mission. Failures are [CollectPaymentFail]s carrying the reason.
  Future<RepoResponse<CollectPaymentResult>> collectPayment(
    CollectPaymentInput input,
  );

  /// Live stream of a payment row's state, keyed by its id.
  Stream<RepoResponse<PaymentEntity>> watchPayment(String paymentId);
}
