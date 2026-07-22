import 'package:zuru/modules/payments/domain/entities/stk_push_result.entity.dart';

class StkPushResultModel extends StkPushResult {
  StkPushResultModel({
    required super.message,
    required super.paymentId,
    super.checkoutRequestId,
  });

  factory StkPushResultModel.fromMap(Map<String, dynamic> m) =>
      StkPushResultModel(
        message: m['message']?.toString() ?? '',
        paymentId: m['payment_id']?.toString() ?? '',
        checkoutRequestId: m['checkout_request_id']?.toString(),
      );
}
