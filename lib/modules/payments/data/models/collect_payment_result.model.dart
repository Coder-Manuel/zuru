import 'package:zuru/modules/payments/domain/entities/collect_payment_result.entity.dart';

class CollectPaymentResultModel extends CollectPaymentResult {
  CollectPaymentResultModel({
    required super.paymentId,
    super.message,
    super.invoiceId,
    super.checkoutUrl,
    super.checkoutId,
  });

  factory CollectPaymentResultModel.fromMap(Map<String, dynamic> m) =>
      CollectPaymentResultModel(
        paymentId: m['payment_id']?.toString() ?? '',
        message: m['message']?.toString(),
        invoiceId: m['invoice_id']?.toString(),
        checkoutUrl: m['checkout_url']?.toString(),
        checkoutId: m['checkout_id']?.toString(),
      );
}
