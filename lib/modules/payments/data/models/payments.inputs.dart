enum PaymentMethod { mpesa, card }

class CollectPaymentInput {
  final String missionId;
  final PaymentMethod method;
  final String? phoneNumber; // required for mpesa
  final String? email; // optional, card only
  final String? redirectUrl; // optional, card only

  const CollectPaymentInput({
    required this.missionId,
    required this.method,
    this.phoneNumber,
    this.email,
    this.redirectUrl,
  });

  Map<String, dynamic> toBody() => {
    'mission_id': missionId,
    'method': method.name,
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (email != null) 'email': email,
    if (redirectUrl != null) 'redirect_url': redirectUrl,
  };
}
