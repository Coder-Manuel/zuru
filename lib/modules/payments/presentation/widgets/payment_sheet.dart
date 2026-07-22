import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/modules/payments/presentation/controllers/payment_controller.dart';

Future<bool> showPaymentSheet({
  required String missionId,
  required String amountLabel,
  String? phone,
}) async {
  Get.put(
    PaymentController(
      missionId: missionId,
      amountLabel: amountLabel,
      initialPhone: phone,
    ),
  );

  final result = await Get.bottomSheet<bool>(
    const PaymentSheet(),
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
  );

  await Get.delete<PaymentController>();
  return result ?? false;
}

class PaymentSheet extends GetView<PaymentController> {
  const PaymentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ClientColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ClientColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              return switch (controller.state.value) {
                PaymentUiState.form => const _FormView(),
                PaymentUiState.sending => const _ProcessingView(
                  title: 'Sending STK push…',
                  subtitle: 'Setting up your M-Pesa payment…',
                ),
                PaymentUiState.awaitingPin => const _ProcessingView(
                  title: 'Enter M-PESA PIN to complete payment',
                  subtitle:
                      "STK sent · check your phone for the prompt.\n"
                      "We're confirming your payment…",
                ),
                PaymentUiState.success => const _SuccessView(),
                PaymentUiState.failed => const _FailedView(),
              };
            }),
          ],
        ),
      ),
    );
  }
}

class _FormView extends GetView<PaymentController> {
  const _FormView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Complete payment',
            style: TextStyle(
              color: ClientColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Pay with M-Pesa to publish your live check',
            style: TextStyle(color: ClientColors.textSecondary, fontSize: 13),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: ClientColors.inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ClientColors.divider.withAlpha(80)),
          ),
          child: Column(
            children: [
              Text(
                'AMOUNT TO PAY',
                style: TextStyle(
                  color: ClientColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                controller.amountLabel,
                style: TextStyle(
                  color: ClientColors.primary,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'M-PESA NUMBER',
          style: TextStyle(
            color: ClientColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller.phoneCtrl,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: ClientColors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'e.g. 0712 345 678',
            hintStyle: TextStyle(color: ClientColors.textSecondary),
            prefixIcon: Icon(
              Icons.phone_iphone_rounded,
              color: ClientColors.textSecondary,
              size: 20,
            ),
            filled: true,
            fillColor: ClientColors.inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ClientColors.primary, width: 1.5),
            ),
          ),
        ),
        Obx(() {
          if (controller.error.value.isEmpty) return const SizedBox(height: 20);
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text(
              controller.error.value,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
            ),
          );
        }),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: controller.pay,
            style: ElevatedButton.styleFrom(
              backgroundColor: ClientColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: Text(
              'Pay ${controller.amountLabel}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: controller.cancel,
            child: Text(
              'Cancel',
              style: TextStyle(color: ClientColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProcessingView extends GetView<PaymentController> {
  final String title;
  final String subtitle;
  const _ProcessingView({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(ClientColors.primary),
                  backgroundColor: ClientColors.inputBg,
                ),
              ),
              Icon(
                    Icons.smartphone_rounded,
                    color: ClientColors.primary,
                    size: 36,
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(
                    begin: 0.9,
                    end: 1.08,
                    duration: 700.ms,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ClientColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ClientColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: controller.cancel,
          child: Text(
            'Cancel',
            style: TextStyle(color: ClientColors.textSecondary),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF22C55E),
                size: 54,
              ),
            )
            .animate()
            .scale(
              begin: const Offset(0.4, 0.4),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: 200.ms),
        const SizedBox(height: 24),
        Text(
          'Payment confirmed',
          style: TextStyle(
            color: ClientColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Publishing your live check…',
          style: TextStyle(color: ClientColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _FailedView extends GetView<PaymentController> {
  const _FailedView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close_rounded,
            color: Color(0xFFEF4444),
            size: 50,
          ),
        ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text(
          'Payment failed',
          style: TextStyle(
            color: ClientColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Text(
            controller.error.value.isEmpty
                ? 'Something went wrong. Please try again.'
                : controller.error.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ClientColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: controller.retry,
            style: ElevatedButton.styleFrom(
              backgroundColor: ClientColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: const Text(
              'Try again',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: controller.cancel,
          child: Text(
            'Close',
            style: TextStyle(color: ClientColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
