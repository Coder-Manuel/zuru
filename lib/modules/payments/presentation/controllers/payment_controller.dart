import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:zuru/modules/payments/data/models/payments.inputs.dart';
import 'package:zuru/modules/payments/domain/entities/payment.entity.dart';
import 'package:zuru/modules/payments/domain/usecases/initiate_stk_push.usecase.dart';
import 'package:zuru/modules/payments/domain/usecases/watch_payment.usecase.dart';

enum PaymentUiState { form, processing, success, failed }

class PaymentController extends GetxController {
  final String missionId;
  final String amountLabel;

  PaymentController({
    required this.missionId,
    required this.amountLabel,
    String? initialPhone,
  }) : phoneCtrl = TextEditingController(text: initialPhone ?? '');

  final _initiateStk = Get.find<InitiateStkPushUseCase>();
  final _watchPayment = Get.find<WatchPaymentUseCase>();

  final TextEditingController phoneCtrl;

  final Rx<PaymentUiState> state = PaymentUiState.form.obs;
  final RxString error = ''.obs;

  StreamSubscription<dynamic>? _sub;
  Timer? _timeout;
  static const _timeoutDuration = Duration(seconds: 90);

  Future<void> pay() async {
    final phone = phoneCtrl.text.trim();
    if (!_isValidPhone(phone)) {
      error.value = 'Enter a valid M-Pesa phone number';
      return;
    }

    error.value = '';
    state.value = PaymentUiState.processing;

    final result = await _initiateStk(
      StkPushInput(phoneNumber: phone, missionId: missionId),
    );

    result.fold(
      (fail) => _fail(fail.message),
      (stk) => _watch(stk.paymentId),
    );
  }

  void retry() {
    error.value = '';
    state.value = PaymentUiState.form;
  }

  void cancel() {
    _cleanup();
    Get.back(result: false);
  }

  void _watch(String paymentId) {
    _sub?.cancel();
    _startTimeout();

    _sub = _watchPayment(paymentId).listen((response) {
      response.fold((_) {}, (payment) {
        switch (payment.status) {
          case PaymentStatus.success:
            _succeed();
          case PaymentStatus.failed:
            _fail(payment.resultDesc ?? 'Payment failed. Please try again.');
          case PaymentStatus.processing:
          case PaymentStatus.unknown:
            break;
        }
      });
    }, onError: (_) {});
  }

  void _succeed() {
    _cleanup();
    state.value = PaymentUiState.success;
    Future.delayed(
      const Duration(milliseconds: 1600),
      () => Get.back(result: true),
    );
  }

  void _fail(String message) {
    _cleanup();
    error.value = message;
    state.value = PaymentUiState.failed;
  }

  void _startTimeout() {
    _timeout?.cancel();
    _timeout = Timer(_timeoutDuration, () {
      if (state.value == PaymentUiState.processing) {
        _fail('Payment timed out. Please try again.');
      }
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
    phoneCtrl.dispose();
    super.onClose();
  }
}
