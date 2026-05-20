import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zuru/config/colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/payments/domain/entities/statement.entity.dart';
import 'package:zuru/modules/payments/presentation/controllers/statements_controller.dart';

class StatementsPage extends GetView<StatementsController> {
  static const String route = '/statements';

  const StatementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.textPrimary,
                        size: 26,
                      ),
                    ),
                  ),
                  20.horizontalSpace,
                  const Text(
                    'Statements',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            28.verticalSpace,

            // ── Body ───────────────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const _StatementsShimmer();
                }

                if (controller.hasError.value) {
                  return _ErrorView(onRetry: controller.fetchStatements);
                }

                if (controller.statements.isEmpty) {
                  return const _EmptyView();
                }

                return _StatementsList(statements: controller.statements);
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loaded list with staggered slide-in ───────────────────────────────────────

class _StatementsList extends StatefulWidget {
  final List<StatementEntity> statements;
  const _StatementsList({required this.statements});

  @override
  State<_StatementsList> createState() => _StatementsListState();
}

class _StatementsListState extends State<_StatementsList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();
    final count = widget.statements.length;
    // Total duration scales with count but is capped so it doesn't feel slow.
    final totalMs = (80 * count + 200).clamp(300, 900);

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );

    _fades = List.generate(count, (i) {
      final start = (i * 0.12).clamp(0.0, 0.8);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _slides = List.generate(count, (i) {
      final start = (i * 0.12).clamp(0.0, 0.8);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0.08, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: widget.statements.length,
      separatorBuilder: (context, index) => 12.verticalSpace,
      itemBuilder: (context, i) {
        return FadeTransition(
          opacity: _fades[i],
          child: SlideTransition(
            position: _slides[i],
            child: _StatementCard(statement: widget.statements[i]),
          ),
        );
      },
    );
  }
}

// ── Single statement card ─────────────────────────────────────────────────────

class _StatementCard extends StatelessWidget {
  final StatementEntity statement;
  const _StatementCard({required this.statement});

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (statement.status) {
      StatementStatus.disbursed => ('DISBURSED', AppColors.textAccent),
      StatementStatus.pending => ('PENDING', const Color(0xFFF5A020)),
      StatementStatus.failed => ('FAILED', const Color(0xFFCC1E1E)),
    };

    final dateLabel = _formatDate(statement.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: date + amount ──────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      8.verticalSpace,
                      Text(
                        '${statement.missionTitle} · ${statement.location}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                16.horizontalSpace,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      statement.formattedAmount,
                      style: const TextStyle(
                        color: AppColors.textAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    6.verticalSpace,
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            18.verticalSpace,

            // ── Channel row ─────────────────────────────────────────────────
            Container(
              height: 1,
              color: AppColors.divider,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CHANNEL',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    statement.channel,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Converts an ISO timestamp to "MAR 24, 2026" format.
  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Shimmer skeleton ──────────────────────────────────────────────────────────

class _StatementsShimmer extends StatelessWidget {
  const _StatementsShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: const Color(0xFF1C2E1E),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4,
        separatorBuilder: (context, index) => 12.verticalSpace,
        itemBuilder: (context, index) => const _ShimmerCard(),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 100, height: 11),
                    8.verticalSpace,
                    _ShimmerBox(width: double.infinity, height: 15),
                  ],
                ),
              ),
              16.horizontalSpace,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ShimmerBox(width: 80, height: 18),
                  6.verticalSpace,
                  _ShimmerBox(width: 64, height: 11),
                ],
              ),
            ],
          ),
          18.verticalSpace,
          Container(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ShimmerBox(width: 64, height: 11),
                _ShimmerBox(width: 120, height: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  const _ShimmerBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ── Empty & error states ──────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: AppColors.textSecondary,
            size: 52,
          ),
          20.verticalSpace,
          const Text(
            'No statements yet.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.scoutMarker,
            size: 48,
          ),
          20.verticalSpace,
          const Text(
            'Failed to load statements.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          16.verticalSpace,
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
