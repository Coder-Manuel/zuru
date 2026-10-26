// On-device check for BUG-002: with the real soft keyboard open, the payment
// sheet's buttons still take taps.
//
// The sheet is opened through showPaymentSheet (a real Get.bottomSheet). The
// form never reaches the network, so the use cases sit on a repository that
// throws if called.
//
// Needs a visible software keyboard: on an emulator, turn on "show virtual
// keyboard" (adb shell settings put secure show_ime_with_hard_keyboard 1); on
// a simulator, uncheck I/O > Keyboard > Connect Hardware Keyboard.
//
//   fvm flutter test integration_test/payment_sheet_keyboard_check.dart -d <id>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zuru/modules/payments/domain/repository/payments_repository.dart';
import 'package:zuru/modules/payments/domain/usecases/collect_payment.usecase.dart';
import 'package:zuru/modules/payments/domain/usecases/watch_payment.usecase.dart';
import 'package:zuru/modules/payments/presentation/services/card_checkout_launcher.dart';
import 'package:zuru/modules/payments/presentation/widgets/payment_sheet.dart';

class _UnusedPaymentsRepository implements PaymentsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _UnusedCardCheckout implements CardCheckoutLauncher {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final repo = _UnusedPaymentsRepository();
    Get.put<CollectPaymentUseCase>(CollectPaymentUseCase(repo: repo));
    Get.put<WatchPaymentUseCase>(WatchPaymentUseCase(repo: repo));
    Get.put<CardCheckoutLauncher>(_UnusedCardCheckout());
  });

  tearDown(Get.reset);

  /// Pumps until [done] holds, up to [timeout].
  Future<bool> pumpUntil(
    WidgetTester tester,
    bool Function() done, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      if (done()) return true;
      await tester.pump(const Duration(milliseconds: 200));
    }
    return done();
  }

  double keyboardInset(WidgetTester tester) => tester.view.viewInsets.bottom;

  testWidgets('Pay and Cancel respond while the soft keyboard is open', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (_) => ElevatedButton(
                onPressed: () =>
                    showPaymentSheet(missionId: 'm1', amountLabel: 'KES 500'),
                child: const Text('Open payment'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open payment'));
    await tester.pumpAndSettle();
    expect(find.text('Pay KES 500'), findsOneWidget);

    await tester.tap(find.byType(TextField));
    // ignore: avoid_print
    print('QA: waiting for the soft keyboard');
    final keyboardUp = await pumpUntil(tester, () => keyboardInset(tester) > 0);
    expect(
      keyboardUp,
      isTrue,
      reason: 'No soft keyboard appeared; see the setup note at the top.',
    );
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('QA: KEYBOARD_UP inset=${keyboardInset(tester)}');
    // Window for a screenshot of the sheet above the keyboard.
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);

    // Both buttons show above the keyboard without scrolling.
    final visible = tester.getRect(find.byType(SingleChildScrollView));
    final payRect = tester.getRect(find.text('Pay KES 500'));
    final cancelRect = tester.getRect(find.text('Cancel'));
    // ignore: avoid_print
    print('QA: VISIBLE sheet=$visible pay=$payRect cancel=$cancelRect');
    expect(payRect.bottom, lessThanOrEqualTo(visible.bottom));
    expect(cancelRect.bottom, lessThanOrEqualTo(visible.bottom));

    // The bug: Pay is drawn but taps never reach it.
    await tester.tap(find.text('Pay KES 500'));
    await tester.pump();

    // The empty number fails validation, which proves the tap landed.
    expect(find.text('Enter a valid M-Pesa phone number'), findsOneWidget);
    // And Pay dismissed the keyboard.
    expect(await pumpUntil(tester, () => keyboardInset(tester) == 0), isTrue);
    // ignore: avoid_print
    print('QA: PAY_TAPPED keyboard closed');

    // Keyboard up again, then Cancel must close the sheet.
    await tester.tap(find.byType(TextField));
    expect(await pumpUntil(tester, () => keyboardInset(tester) > 0), isTrue);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Pay KES 500'), findsNothing);
    // ignore: avoid_print
    print('QA: CANCEL_TAPPED sheet closed');
  });
}
