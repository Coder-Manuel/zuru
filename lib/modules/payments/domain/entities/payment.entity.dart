import 'package:zuru/core/entities/base.entity.dart';
import 'package:zuru/modules/payments/data/models/payments.inputs.dart';

enum PaymentStatus {
  pending,
  processing,
  success,
  failed,
  cancelled,
  refunded,
  unknown;

  static PaymentStatus fromApi(String? value) => switch (value?.toLowerCase()) {
    'pending' => PaymentStatus.pending,
    'processing' => PaymentStatus.processing,
    'success' => PaymentStatus.success,
    'failed' => PaymentStatus.failed,
    'cancelled' => PaymentStatus.cancelled,
    'refunded' => PaymentStatus.refunded,
    _ => PaymentStatus.unknown,
  };

  bool get isTerminal =>
      this == success ||
      this == failed ||
      this == cancelled ||
      this == refunded;
}

abstract class PaymentEntity extends BaseEntity {
  final String? missionId;
  final PaymentStatus status;
  final double? amount;
  final String? currency;
  final String? resultDesc;
  final PaymentMethod? paymentMethod;

  PaymentEntity({
    super.id,
    super.createdAt,
    super.updatedAt,
    this.missionId,
    this.status = PaymentStatus.processing,
    this.amount,
    this.currency,
    this.resultDesc,
    this.paymentMethod,
  });
}
