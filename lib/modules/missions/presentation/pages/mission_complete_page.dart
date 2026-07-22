import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/missions/data/models/mission.model.dart';

class MissionCompletePage extends StatelessWidget {
  static const String route = '/mission-complete';

  const MissionCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    final mission = Get.arguments as MissionModel;

    return Scaffold(
      backgroundColor: ClientColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Success icon ─────────────────────────────────────────────
              _SuccessIcon(),

              32.verticalSpace,

              // ── Title ────────────────────────────────────────────────────
              Text(
                'Live Check Complete!',
                style: TextStyle(
                  color: ClientColors.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),

              14.verticalSpace,

              Text(
                '${mission.formattedPrice} will be disbursed to your payment method.',
                style: TextStyle(
                  color: ClientColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              40.verticalSpace,

              // ── Stats card ───────────────────────────────────────────────
              _StatsCard(mission: mission),

              const Spacer(flex: 3),

              // ── CTA ──────────────────────────────────────────────────────
              ElevatedButton(
                onPressed: () => Get.until((page) => page.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClientColors.primary,
                  foregroundColor: ClientColors.background,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Back to Radar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),

              24.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Success icon ──────────────────────────────────────────────────────────────
class _SuccessIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ClientColors.primary,
        boxShadow: [
          BoxShadow(
            color: ClientColors.primary.withAlpha(80),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(
        Icons.check_circle_outline_rounded,
        color: ClientColors.background,
        size: 48,
      ),
    );
  }
}

// ── Mission stats card ────────────────────────────────────────────────────────
class _StatsCard extends StatelessWidget {
  final MissionModel mission;

  const _StatsCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: ClientColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'LIVE CHECK STATS',
            style: TextStyle(
              color: ClientColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          20.verticalSpace,
          _StatRow(label: 'Duration', value: mission.durationLabel),
          _StatDivider(),
          _StatRow(
            label: 'Base Pay',
            value: mission.formattedPrice,
            valueBold: true,
          ),
          _StatDivider(),
          _StatRow(
            label: 'Total',
            value: '+ KES ${mission.formattedPrice}',
            valueColor: ClientColors.primary,
            valueBold: true,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: ClientColors.textSecondary, fontSize: 14.5),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? ClientColors.textPrimary,
              fontSize: 14.5,
              fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(color: ClientColors.divider, height: 1, thickness: 1);
  }
}
