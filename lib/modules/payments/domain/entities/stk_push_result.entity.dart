abstract class StkPushResult {
  final String message;
  final String paymentId;
  final String? checkoutRequestId;

  StkPushResult({
    required this.message,
    required this.paymentId,
    this.checkoutRequestId,
  });
}
