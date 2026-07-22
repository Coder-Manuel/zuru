import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/core/types/usecase.dart';
import 'package:zuru/modules/payments/domain/entities/payment.entity.dart';
import 'package:zuru/modules/payments/domain/repository/payments_repository.dart';

class WatchPaymentUseCase implements StreamUseCase<PaymentEntity, String> {
  final PaymentsRepository repo;
  WatchPaymentUseCase({required this.repo});

  @override
  Stream<RepoResponse<PaymentEntity>> call(String paymentId) =>
      repo.watchPayment(paymentId);
}
