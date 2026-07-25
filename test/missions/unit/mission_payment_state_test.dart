// Unit tests for the pay-after-accept state machine on [MissionEntity].
//
// A live request is created unpaid and sits with the target guide; nothing is
// owed until they accept. Once accepted, the client owes payment and the guide
// stays blocked until `published_at` is set by the payment callback.
import 'package:flutter_test/flutter_test.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/data/models/mission.model.dart';

MissionModel mission({
  required MissionStatus status,
  MissionType type = MissionType.liveRequest,
  String? publishedAt,
  String? acceptedAt,
}) {
  return MissionModel(
    id: 'm1',
    description: 'Show me the balcony view',
    currency: 'KES',
    price: 2400,
    durationInSec: 900,
    address: 'Riverside Drive',
    status: status,
    type: type,
    publishedAt: publishedAt,
    acceptedAt: acceptedAt,
  );
}

void main() {
  group('live request awaiting the guide', () {
    final subject = mission(status: MissionStatus.requested);

    test('is waiting on the guide, not the client', () {
      expect(subject.awaitingScoutResponse, isTrue);
      expect(subject.awaitingClientPayment, isFalse);
    });

    test('is not payable — nothing is owed until it is accepted', () {
      expect(subject.isPayable, isFalse);
    });
  });

  group('live request accepted but unpaid', () {
    final acceptedAt = DateTime.now()
        .toUtc()
        .subtract(const Duration(minutes: 5))
        .toIso8601String();
    final subject = mission(
      status: MissionStatus.accepted,
      acceptedAt: acceptedAt,
    );

    test('owes payment and can be paid for', () {
      expect(subject.awaitingClientPayment, isTrue);
      expect(subject.awaitingScoutResponse, isFalse);
      expect(subject.isPayable, isTrue);
    });

    test('leaves the rest of the payment window on the clock', () {
      final left = subject.paymentTimeLeft;
      expect(left, isNotNull);
      expect(left!.inMinutes, closeTo(25, 1));
    });

    test('clamps an elapsed window to zero rather than going negative', () {
      final expired = mission(
        status: MissionStatus.accepted,
        acceptedAt: DateTime.now()
            .toUtc()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
      );
      expect(expired.paymentTimeLeft, Duration.zero);
    });

    test('has no deadline when accepted_at is missing', () {
      final unknown = mission(status: MissionStatus.accepted);
      expect(unknown.paymentDeadline, isNull);
      expect(unknown.paymentTimeLeft, isNull);
    });
  });

  group('live request paid for', () {
    final subject = mission(
      status: MissionStatus.accepted,
      acceptedAt: DateTime.now().toUtc().toIso8601String(),
      publishedAt: DateTime.now().toUtc().toIso8601String(),
    );

    test('unblocks the guide and is no longer payable', () {
      expect(subject.isPublished, isTrue);
      expect(subject.awaitingClientPayment, isFalse);
      expect(subject.isPayable, isFalse);
    });
  });

  group('declined live request', () {
    final subject = mission(
      status: MissionStatus.declined,
      acceptedAt: DateTime.now().toUtc().toIso8601String(),
    );

    test('asks the client for nothing', () {
      expect(subject.awaitingClientPayment, isFalse);
      expect(subject.awaitingScoutResponse, isFalse);
      expect(subject.isPayable, isFalse);
    });
  });

  group('pool live check (not a live request)', () {
    test('is still pay-to-publish while open', () {
      final open = mission(
        status: MissionStatus.open,
        type: MissionType.surveillance,
      );
      expect(open.isPayable, isTrue);
      expect(open.awaitingScoutResponse, isFalse);
      expect(open.awaitingClientPayment, isFalse);
    });

    test('is not payable once published', () {
      final published = mission(
        status: MissionStatus.open,
        type: MissionType.surveillance,
        publishedAt: DateTime.now().toUtc().toIso8601String(),
      );
      expect(published.isPayable, isFalse);
    });
  });
}
