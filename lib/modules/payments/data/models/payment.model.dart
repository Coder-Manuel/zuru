import 'package:zuru/modules/payments/domain/entities/payment.entity.dart';

class PaymentModel extends PaymentEntity {
  PaymentModel({
    super.id,
    super.createdAt,
    super.updatedAt,
    super.missionId,
    super.status,
    super.amount,
    super.currency,
    super.resultDesc,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> m) => PaymentModel(
    id: m['id']?.toString(),
    createdAt: m['created_at']?.toString(),
    updatedAt: m['updated_at']?.toString(),
    missionId: m['mission_id']?.toString(),
    status: PaymentStatus.fromApi(m['status']?.toString()),
    amount: (m['amount'] as num?)?.toDouble(),
    currency: m['currency']?.toString(),
    resultDesc: m['result_desc']?.toString() ?? m['message']?.toString(),
  );
}
