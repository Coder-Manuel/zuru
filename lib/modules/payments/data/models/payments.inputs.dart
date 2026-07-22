class StkPushInput {
  final String phoneNumber;
  final String missionId;

  const StkPushInput({required this.phoneNumber, required this.missionId});

  Map<String, dynamic> toBody() => {
    'phone_number': phoneNumber,
    'mission_id': missionId,
  };
}
