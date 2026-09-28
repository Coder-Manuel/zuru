import 'package:zuru/core/types/repo_reponse.type.dart';

abstract class CollectPaymentResult {
  final String paymentId;
  final String? message; // mpesa
  final String? invoiceId; // mpesa
  final String? checkoutUrl; // card — open this
  final String? checkoutId; // card

  CollectPaymentResult({
    required this.paymentId,
    this.message,
    this.invoiceId,
    this.checkoutUrl,
    this.checkoutId,
  });
}

/// How `intasend-collect` rejected a request, derived from its status code.
enum CollectFailKind {
  /// 400 — bad input; show the message and stay on the form.
  invalid,

  /// 403 / 404 — not payable by this caller; show a generic failure.
  forbidden,

  /// 409 — the mission is already paid; the UI treats this as success.
  alreadyPaid,

  /// 502, network errors, anything else — offer a retry.
  retryable,
}

class CollectPaymentFail extends ApiFail {
  final CollectFailKind kind;

  CollectPaymentFail(super.message, {required this.kind});
}
