import 'package:zuru/core/entities/base.entity.dart';

enum StatementStatus { disbursed, pending, failed }

abstract class StatementEntity extends BaseEntity {
  final String missionTitle;
  final String location;
  final double amount;
  final String currency;
  final StatementStatus status;

  /// Human-readable payment channel, e.g. "M-PESA (07*****89)".
  final String channel;

  StatementEntity({
    super.id,
    super.createdAt,
    super.updatedAt,
    required this.missionTitle,
    required this.location,
    required this.amount,
    required this.currency,
    required this.status,
    required this.channel,
  });

  /// "KES 2,500" style.
  String get formattedAmount => '$currency ${_commaSeparate(amount)}';

  String _commaSeparate(double n) {
    final s = n.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
