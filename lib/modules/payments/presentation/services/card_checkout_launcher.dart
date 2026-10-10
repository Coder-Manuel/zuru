import 'package:get/get.dart';
import 'package:zuru/modules/payments/presentation/pages/card_checkout_page.dart';

/// Opens the IntaSend hosted card checkout and resolves once the customer
/// leaves it.
///
/// Behind an interface so [PaymentController] can be tested without pushing a
/// real route — and so the checkout surface (in-app webview today, external
/// browser before) can change without touching the controller.
abstract class CardCheckoutLauncher {
  Future<CardCheckoutOutcome> open(String checkoutUrl);
}

class CardCheckoutLauncherImpl implements CardCheckoutLauncher {
  @override
  Future<CardCheckoutOutcome> open(String checkoutUrl) async {
    final outcome = await Get.to<CardCheckoutOutcome>(
      () => CardCheckoutPage(checkoutUrl: checkoutUrl),
      fullscreenDialog: true,
    );
    // A swipe-back pops without a result.
    return outcome ?? CardCheckoutOutcome.dismissed;
  }
}
