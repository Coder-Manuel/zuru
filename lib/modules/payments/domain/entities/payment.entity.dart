import 'package:zuru/core/entities/base.entity.dart';

enum PaymentStatus {
  processing,
  success,
  failed,
  unknown;

  static PaymentStatus fromApi(String? value) => switch (value?.toLowerCase()) {
    'processing' => PaymentStatus.processing,
    'success' => PaymentStatus.success,
    'failed' => PaymentStatus.failed,
    _ => PaymentStatus.unknown,
  };

  bool get isTerminal => this == success || this == failed;
}

abstract class PaymentEntity extends BaseEntity {
  final String? missionId;
  final PaymentStatus status;
  final double? amount;
  final String? currency;
  final String? resultDesc;

  PaymentEntity({
    super.id,
    super.createdAt,
    super.updatedAt,
    this.missionId,
    this.status = PaymentStatus.processing,
    this.amount,
    this.currency,
    this.resultDesc,
  });
}
