import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:zuru/core/services/url_launcher_service/url_launcher_service.dart';
import 'package:zuru/core/types/repo_reponse.type.dart';
import 'package:zuru/modules/payments/data/models/payments.inputs.dart';
import 'package:zuru/modules/payments/domain/entities/collect_payment_result.entity.dart';
import 'package:zuru/modules/payments/domain/entities/payment.entity.dart';
import 'package:zuru/modules/payments/domain/usecases/collect_payment.usecase.dart';
import 'package:zuru/modules/payments/domain/usecases/watch_payment.usecase.dart';

enum PaymentUiState {
  form,
  sending,
  awaitingPin,
  awaitingCard,
  success,
  failed,
}

class PaymentController extends GetxController {
  final String missionId;
  final String amountLabel;

  PaymentController({
    required this.missionId,
    required this.amountLabel,
    String? initialPhone,
  }) : phoneCtrl = TextEditingController(text: initialPhone ?? '');

  final _collectPayment = Get.find<CollectPaymentUseCase>();
  final _watchPayment = Get.find<WatchPaymentUseCase>();
  final _urlLauncher = Get.find<UrlLauncherService>();

  final TextEditingController phoneCtrl;

  final Rx<PaymentUiState> state = PaymentUiState.form.obs;
  final Rx<PaymentMethod> method = PaymentMethod.mpesa.obs;
  final RxString error = ''.obs;

  /// False when the server said this mission can't be paid by this user, so
  /// retrying would only fail again.
  final RxBool canRetry = true.obs;

  /// True when the watch timed out: the outcome is unknown, not a failure.
  final RxBool timedOut = false.obs;

  StreamSubscription<dynamic>? _sub;
  Timer? _timeout;
  String? _paymentId;
  AppLifecycleListener? _lifecycle;

  static const _mpesaTimeout = Duration(seconds: 90);
  static const _cardTimeout = Duration(minutes: 10);

  bool get _isAwaiting =>
      state.value == PaymentUiState.awaitingPin ||
      state.value == PaymentUiState.awaitingCard;

  @override
  void onInit() {
    super.onInit();
    // The card flow leaves the app; the realtime socket can drop while we're
    // backgrounded, so re-subscribe on resume to pick up the latest row.
    _lifecycle = AppLifecycleListener(onResume: refreshPayment);
  }

  void setMethod(PaymentMethod value) {
    method.value = value;
    error.value = '';
  }

  Future<void> pay() async {
    final selected = method.value;
    final phone = phoneCtrl.text.trim();
    if (selected == PaymentMethod.mpesa && !_isValidPhone(phone)) {
      error.value = 'Enter a valid M-Pesa phone number';
      return;
    }

    error.value = '';
    canRetry.value = true;
    timedOut.value = false;
    state.value = PaymentUiState.sending;

    final result = await _collectPayment(
      CollectPaymentInput(
        missionId: missionId,
        method: selected,
        phoneNumber: selected == PaymentMethod.mpesa ? phone : null,
      ),
    );
    if (isClosed || state.value != PaymentUiState.sending) return;

    await result.fold(
      (fail) async => _onCollectFailed(fail),
      (collected) async => _onCollected(selected, collected),
    );
  }

  /// Re-subscribes to the payment row. Used on app resume and by the
  /// "I've completed payment" button; the datasource emits the current row
  /// on subscribe, so a payment that settled meanwhile is picked up.
  void refreshPayment() {
    final id = _paymentId;
    if (id == null || !_isAwaiting) return;
    _watch(id);
  }

  void retry() {
    error.value = '';
    canRetry.value = true;
    timedOut.value = false;
    state.value = PaymentUiState.form;
  }

  void cancel() {
    _cleanup();
    Get.back(result: false);
  }

  void _onCollectFailed(ApiFail fail) {
    if (fail is! CollectPaymentFail) {
      _fail(fail.message);
      return;
    }
    switch (fail.kind) {
      case CollectFailKind.alreadyPaid:
        _succeed();
      case CollectFailKind.invalid:
        error.value = fail.message;
        state.value = PaymentUiState.form;
      case CollectFailKind.forbidden:
        _fail(fail.message, retryable: false);
      case CollectFailKind.retryable:
        _fail(fail.message);
    }
  }

  Future<void> _onCollected(
    PaymentMethod selected,
    CollectPaymentResult collected,
  ) async {
    // Watch before opening anything so a fast webhook can't be missed.
    _paymentId = collected.paymentId;
    _watch(collected.paymentId);

    if (selected == PaymentMethod.mpesa) {
      state.value = PaymentUiState.awaitingPin;
      _startTimeout(_mpesaTimeout);
      return;
    }

    final url = collected.checkoutUrl;
    final uri = url == null ? null : Uri.tryParse(url);
    final opened = uri != null && await _urlLauncher.launch(uri);
    if (isClosed || state.value != PaymentUiState.sending) return;
    if (!opened) {
      _fail('Could not open the payment page.');
      return;
    }
    state.value = PaymentUiState.awaitingCard;
    _startTimeout(_cardTimeout);
  }

  void _watch(String paymentId) {
    // The server may hand back an in-flight row we're already watching.
    _sub?.cancel();

    _sub = _watchPayment(paymentId).listen((response) {
      response.fold((_) {}, (payment) {
        if (!_isAwaiting && state.value != PaymentUiState.sending) return;
        switch (payment.status) {
          case PaymentStatus.success:
            _succeed();
          case PaymentStatus.failed:
            _fail(payment.resultDesc ?? 'Payment failed. Please try again.');
          case PaymentStatus.cancelled:
            _fail('Payment was cancelled.');
          case PaymentStatus.refunded:
            _fail('This payment was refunded.');
          case PaymentStatus.pending:
          case PaymentStatus.processing:
          case PaymentStatus.unknown:
            break;
        }
      });
    }, onError: (_) {});
  }

  void _succeed() {
    if (state.value == PaymentUiState.success) return;
    _cleanup();
    state.value = PaymentUiState.success;
    Future.delayed(
      const Duration(milliseconds: 1600),
      () => Get.back(result: true),
    );
  }

  void _fail(String message, {bool retryable = true}) {
    _cleanup();
    error.value = message;
    canRetry.value = retryable;
    state.value = PaymentUiState.failed;
  }

  void _startTimeout(Duration duration) {
    _timeout?.cancel();
    final awaiting = state.value;
    _timeout = Timer(duration, () {
      if (state.value != awaiting) return;
      _fail(
        "We couldn't confirm your payment yet. If it goes through, "
        'your mission will update automatically.',
      );
      timedOut.value = true;
    });
  }

  void _cleanup() {
    _sub?.cancel();
    _sub = null;
    _timeout?.cancel();
    _timeout = null;
  }

  bool _isValidPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 9;
  }

  @override
  void onClose() {
    _cleanup();
    _lifecycle?.dispose();
    phoneCtrl.dispose();
    super.onClose();
  }
}
