// Widget tests for [PaymentSheet] with the soft keyboard open (BUG-002).
//
// The sheet is opened the way the app opens it, through showPaymentSheet (a
// real Get.bottomSheet, which lifts itself above the keyboard). The tests
// only drive the form, which never reaches the network, so the use cases sit
// on a repository that throws if anything calls it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:zuru/modules/payments/domain/repository/payments_repository.dart';
import 'package:zuru/modules/payments/domain/usecases/collect_payment.usecase.dart';
import 'package:zuru/modules/payments/domain/usecases/watch_payment.usecase.dart';
import 'package:zuru/modules/payments/presentation/controllers/payment_controller.dart';
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

/// A 6.1" iPhone, and the iOS phone pad's height on it.
const _iPhone = Size(390, 844);
const _phonePad = 300.0;

void main() {
  setUp(() {
    Get.testMode = true;
    // A tap that misses its widget is exactly the bug; make it fail loudly.
    WidgetController.hitTestWarningShouldBeFatal = true;
    final repo = _UnusedPaymentsRepository();
    Get.put<CollectPaymentUseCase>(CollectPaymentUseCase(repo: repo));
    Get.put<WatchPaymentUseCase>(WatchPaymentUseCase(repo: repo));
    Get.put<CardCheckoutLauncher>(_UnusedCardCheckout());
  });

  tearDown(Get.reset);

  final pay = find.text('Pay KES 500');
  final cancel = find.text('Cancel');

  /// Opens the sheet on a [screen]-sized phone, then focuses the number field
  /// with a [keyboard]-tall soft keyboard up.
  Future<void> openWithKeyboard(
    WidgetTester tester, {
    Size screen = _iPhone,
    double keyboard = _phonePad,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = screen;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () =>
                  showPaymentSheet(missionId: 'm1', amountLabel: 'KES 500'),
              child: const Text('Open payment'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open payment'));
    await tester.pumpAndSettle();

    await tester.showKeyboard(find.byType(TextField));
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    await tester.pumpAndSettle();
  }

  /// The part of the sheet the user can see.
  Rect visibleSheet(WidgetTester tester) =>
      tester.getRect(find.byType(SingleChildScrollView));

  testWidgets('on a typical phone, Pay and Cancel show above the keyboard', (
    tester,
  ) async {
    await openWithKeyboard(tester);

    expect(tester.takeException(), isNull);
    final visible = visibleSheet(tester);
    expect(visible.bottom, lessThanOrEqualTo(_iPhone.height - _phonePad));
    // Without scrolling. Adding the keyboard inset on top of the bottom
    // sheet's own left only a sliver of the form visible.
    expect(tester.getRect(pay).bottom, lessThanOrEqualTo(visible.bottom));
    expect(tester.getRect(cancel).bottom, lessThanOrEqualTo(visible.bottom));
  });

  testWidgets('on a small phone, the form scrolls instead of overflowing', (
    tester,
  ) async {
    await openWithKeyboard(tester, screen: const Size(360, 640), keyboard: 290);

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(pay);
    await tester.pumpAndSettle();
    await tester.tap(pay);
    await tester.pump();

    expect(find.text('Enter a valid M-Pesa phone number'), findsOneWidget);
  });

  testWidgets('Pay responds while the keyboard is open', (tester) async {
    await openWithKeyboard(tester);

    await tester.tap(pay);
    await tester.pump();

    // The empty number fails validation, which proves the tap landed.
    expect(find.text('Enter a valid M-Pesa phone number'), findsOneWidget);
    // And the keyboard was dismissed.
    expect(tester.testTextInput.hasAnyClients, isFalse);
  });

  testWidgets('cancelling with the keyboard open closes the sheet cleanly', (
    tester,
  ) async {
    // showPaymentSheet deletes its controller once the sheet is gone; deleting
    // it while the sheet still animated out broke the closing frames.
    await openWithKeyboard(tester);

    await tester.tap(cancel);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(pay, findsNothing);
    expect(Get.isRegistered<PaymentController>(), isFalse);
  });

  testWidgets('tapping outside the number field closes the keyboard', (
    tester,
  ) async {
    await openWithKeyboard(tester);

    // The label itself isn't hit-testable; tap the sheet where it sits.
    await tester.tapAt(tester.getCenter(find.text('AMOUNT TO PAY')));
    await tester.pump();

    expect(tester.testTextInput.hasAnyClients, isFalse);
  });
}
