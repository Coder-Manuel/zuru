import 'package:zuru/modules/payments/domain/entities/statement.entity.dart';

class StatementModel extends StatementEntity {
  StatementModel({
    super.id,
    super.createdAt,
    super.updatedAt,
    required super.missionTitle,
    required super.location,
    required super.amount,
    required super.currency,
    required super.status,
    required super.channel,
  });

  factory StatementModel.fromMap(Map<String, dynamic> map) {
    final statusRaw = (map['status'] as String?)?.toLowerCase() ?? '';
    final status = switch (statusRaw) {
      'disbursed' => StatementStatus.disbursed,
      'pending' => StatementStatus.pending,
      _ => StatementStatus.failed,
    };

    return StatementModel(
      id: map['id']?.toString(),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
      missionTitle: map['mission_title']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency']?.toString() ?? 'KES',
      status: status,
      channel: map['channel']?.toString() ?? '',
    );
  }
}
