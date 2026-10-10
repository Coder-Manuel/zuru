import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zuru/config/client_colors.dart';

/// How the customer left the IntaSend checkout.
///
/// Neither value decides the payment: the webhook does, and the payment sheet
/// is watching the row. This only tells the sheet what to say while it waits.
enum CardCheckoutOutcome {
  /// IntaSend redirected to [CardCheckoutPage.redirectUrl] — the customer
  /// finished the form. The payment may still be settling.
  completed,

  /// The customer backed out of the checkout.
  dismissed,
}

/// In-app browser for the IntaSend hosted card checkout.
///
/// The card form is IntaSend's, served over https — the app never sees card
/// details, which keeps it out of PCI scope.
class CardCheckoutPage extends StatefulWidget {
  static const route = '/card-checkout';

  /// The `checkout_url` returned by the `intasend-collect` function.
  final String checkoutUrl;

  /// Sentinel IntaSend redirects to when the form is done. It is never
  /// fetched: navigation to it is intercepted and the page closes instead,
  /// so the URL does not need to resolve to anything.
  static const redirectUrl = 'https://zuru.app/payment/complete';

  const CardCheckoutPage({super.key, required this.checkoutUrl});

  @override
  State<CardCheckoutPage> createState() => _CardCheckoutPageState();
}

class _CardCheckoutPageState extends State<CardCheckoutPage> {
  late final WebViewController _controller;
  final RxBool _loading = true.obs;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(ClientColors.surface)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (_) {},
          onPageStarted: (_) => _loading.value = true,
          onPageFinished: (_) => _loading.value = false,
          onWebResourceError: (_) => _loading.value = false,
          onNavigationRequest: (request) {
            if (request.url.startsWith(CardCheckoutPage.redirectUrl)) {
              _close(CardCheckoutOutcome.completed);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _close(CardCheckoutOutcome outcome) {
    if (_closed) return; // a redirect can fire more than once
    _closed = true;
    Get.back(result: outcome);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(CardCheckoutOutcome.dismissed);
      },
      child: Scaffold(
        backgroundColor: ClientColors.surface,
        appBar: AppBar(
          backgroundColor: ClientColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: ClientColors.textPrimary),
            onPressed: () => _close(CardCheckoutOutcome.dismissed),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, size: 14, color: ClientColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Secure card payment',
                style: TextStyle(
                  color: ClientColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: Obx(
              () => _loading.value
                  ? LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: ClientColors.inputBg,
                      valueColor: AlwaysStoppedAnimation(ClientColors.primary),
                    )
                  : const SizedBox(height: 2),
            ),
          ),
        ),
        body: SafeArea(child: WebViewWidget(controller: _controller)),
      ),
    );
  }
}
