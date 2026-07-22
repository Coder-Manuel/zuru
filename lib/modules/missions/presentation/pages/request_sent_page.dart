import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/core/routes/app_routes.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/home/presentation/controllers/home_controller.dart';
import 'package:zuru/modules/missions/presentation/widgets/animated_success_ring.dart';

/// Confirmation screen shown after a live request is created.
///
/// Expects [Get.arguments] = `{ 'scoutName': String, 'scheduledAt': String? }`
/// where `scheduledAt` is an ISO-8601 timestamp (null = "now").
class RequestSentPage extends StatelessWidget {
  static const String route = '/request-sent';

  const RequestSentPage({super.key});

  // Client home tab indexes (see HomePage IndexedStack).
  static const _missionsTab = 1;
  static const _scoutsTab = 2;

  Map<String, dynamic> get _args =>
      (Get.arguments as Map?)?.cast<String, dynamic>() ?? const {};

  String get _scoutName => (_args['scoutName'] as String?) ?? 'The guide';

  DateTime? get _scheduledAt {
    final raw = _args['scheduledAt'] as String?;
    return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
  }

  String get _subtitle {
    final schedule = _scheduledAt;
    final tail =
        '$_scoutName will confirm shortly — your payment is safe in escrow.';
    if (schedule == null) return tail;
    final when = DateFormat('EEE d MMM · HH:mm').format(schedule);
    return 'Scheduled for $when. $tail';
  }

  void _goToTab(int index) {
    Get.offAllNamed(AppRoutes.home);
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().changePage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    var step = 0;
    Widget animate(Widget child) {
      final delay = (step++ * 120).ms;
      return child
          .animate()
          .fadeIn(delay: delay, duration: 450.ms)
          .slideY(begin: 0.12, end: 0, delay: delay, duration: 450.ms);
    }

    return Scaffold(
      backgroundColor: ClientColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              animate(const AnimatedSuccessRing(size: 150)),
              28.verticalSpace,
              animate(
                const Text(
                  'Request sent',
                  style: TextStyle(
                    color: ClientColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              16.verticalSpace,
              animate(
                Text(
                  _subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ClientColors.textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
              36.verticalSpace,
              animate(
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _goToTab(_scoutsTab),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClientColors.primary,
                      foregroundColor: ClientColors.background,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Back to feed',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              12.verticalSpace,
              animate(
                TextButton(
                  onPressed: () => _goToTab(_missionsTab),
                  child: const Text(
                    'Review request',
                    style: TextStyle(
                      color: ClientColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
