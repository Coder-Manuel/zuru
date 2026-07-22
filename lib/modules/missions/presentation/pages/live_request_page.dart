import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/core/entities/profile.entity.dart';
import 'package:zuru/core/entities/session_pricing.entity.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/services/fx_service/fx_service.dart';
import 'package:zuru/core/utils/extensions.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/missions/presentation/controllers/live_request_controller.dart';

class LiveRequestPage extends GetView<LiveRequestController> {
  static const String route = '/live-request';

  const LiveRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    var step = 0;
    Widget animate(Widget child) {
      final delay = (step++ * 70).ms;
      return child
          .animate()
          .fadeIn(delay: delay, duration: 420.ms)
          .slideY(begin: 0.12, end: 0, delay: delay, duration: 420.ms);
    }

    return Scaffold(
      backgroundColor: ClientColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              animate(const _Header()),
              4.verticalSpace,
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      20.verticalSpace,
                      animate(_ScoutCard(scout: controller.scout)),
                      28.verticalSpace,

                      animate(const _Label('DURATION')),
                      12.verticalSpace,
                      animate(const _DurationPicker()),
                      28.verticalSpace,

                      animate(const _Label('WHAT DO YOU WANT TO SEE?')),
                      12.verticalSpace,
                      animate(const _DescriptionField()),
                      28.verticalSpace,

                      animate(const _Label('WHEN')),
                      12.verticalSpace,
                      animate(const _WhenToggle()),

                      // Schedule picker (only when scheduling).
                      Obx(() {
                        if (controller.whenMode.value != LiveWhen.schedule) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                24.verticalSpace,
                                const _Label('PICK A DATE'),
                                12.verticalSpace,
                                const _DatePicker(),
                                24.verticalSpace,
                                const _Label('PICK A TIME'),
                                12.verticalSpace,
                                const _TimePicker(),
                                16.verticalSpace,
                                const _ScheduleSummary(),
                              ],
                            )
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.08, end: 0, duration: 300.ms);
                      }),

                      24.verticalSpace,
                      animate(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [_Label('PRICE'), _CurrencyToggle()],
                        ),
                      ),
                      12.verticalSpace,
                      animate(const _FeeBreakdown()),
                      8.verticalSpace,
                      animate(const _LiveRateHint()),
                      20.verticalSpace,
                      // Submit — last item in the page.
                      const _SubmitBar(),
                      25.verticalSpace,
                    ],
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

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: Get.back,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ClientColors.inputBg.withAlpha(150),
              shape: BoxShape.circle,
              border: Border.all(color: ClientColors.divider),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: ClientColors.textPrimary,
              size: 18,
            ),
          ),
        ),
        16.horizontalSpace,
        const Text(
          'Request a Live',
          style: TextStyle(
            color: ClientColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ── Scout card ───────────────────────────────────────────────────────────────

class _ScoutCard extends StatelessWidget {
  final Profile scout;
  const _ScoutCard({required this.scout});

  @override
  Widget build(BuildContext context) {
    final availability = scout.availability ?? ScoutAvailability.offline;
    final availColor = _availabilityColor(availability);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.inputBg.withAlpha(120),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientColors.divider.withAlpha(120)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ClientColors.inputBg,
              border: Border.all(
                color: ClientColors.primary.withAlpha(160),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                _initials(scout.fullName),
                style: const TextStyle(
                  color: ClientColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          14.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scout.fullName.isNotEmpty ? scout.fullName : 'Guide',
                  style: const TextStyle(
                    color: ClientColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                4.verticalSpace,
                Row(
                  children: [
                    if (scout.locality != null &&
                        scout.locality!.isNotEmpty) ...[
                      Flexible(
                        child: Text(
                          scout.locality!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ClientColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        ' · ',
                        style: TextStyle(
                          color: ClientColors.textSecondary.withAlpha(150),
                        ),
                      ),
                    ],
                    Text(
                      scout.rating?.toStringAsFixed(1) ?? '–',
                      style: const TextStyle(
                        color: ClientColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.star_rounded,
                      color: ClientColors.primary,
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
          10.horizontalSpace,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: availColor.withAlpha(24),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: availColor.withAlpha(120)),
            ),
            child: Text(
              availability.label.toUpperCase(),
              style: TextStyle(
                color: availColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Duration ─────────────────────────────────────────────────────────────────

class _DurationPicker extends GetView<LiveRequestController> {
  const _DurationPicker();

  @override
  Widget build(BuildContext context) {
    if (!controller.hasPricing) {
      return const Text(
        'This guide hasn’t set session pricing yet.',
        style: TextStyle(color: ClientColors.textSecondary, fontSize: 14),
      );
    }
    return Obx(
      () => Row(
        children: [
          for (final tier in controller.tiers)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: tier == controller.tiers.last ? 0 : 12,
                ),
                child: _DurationChip(
                  tier: tier,
                  selected: controller.selectedTier.value == tier,
                  onTap: () => controller.selectTier(tier),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final SessionPricing tier;
  final bool selected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.tier,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected
              ? accent.withAlpha(28)
              : ClientColors.inputBg.withAlpha(120),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accent : ClientColors.divider,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withAlpha(50),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              '${tier.durationMinutes}',
              style: TextStyle(
                color: selected ? accent : ClientColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            6.verticalSpace,
            Text(
              'MIN',
              style: TextStyle(
                color: selected ? accent : ClientColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Description ──────────────────────────────────────────────────────────────

class _DescriptionField extends GetView<LiveRequestController> {
  const _DescriptionField();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Form(
        key: controller.formKey,
        child: TextFormField(
          controller: controller.descriptionCTRL,
          maxLines: 4,
          maxLength: LiveRequestController.maxDescriptionChars,
          style: const TextStyle(
            color: ClientColors.textPrimary,
            fontSize: 14,
            height: 1.5,
          ),
          buildCounter:
              (_, {required currentLength, required isFocused, maxLength}) =>
                  Text(
                    '$currentLength/$maxLength characters',
                    style: const TextStyle(
                      color: ClientColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
          validator: (String? v) {
            if (v?.isEmpty ?? true) {
              return 'Description cannot be empty';
            }
            return null;
          },
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText:
                'Describe the specific scene, unit or detail you want verified — '
                'e.g. \'Show me the actual sea view from the balcony and the road '
                'outside.\'',
            hintStyle: TextStyle(
              color: ClientColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ── When toggle ──────────────────────────────────────────────────────────────

class _WhenToggle extends GetView<LiveRequestController> {
  const _WhenToggle();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mode = controller.whenMode.value;
      return Row(
        children: [
          Expanded(
            child: _ToggleButton(
              label: 'Now',
              selected: mode == LiveWhen.now,
              onTap: () => controller.setWhen(LiveWhen.now),
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: _ToggleButton(
              label: 'Schedule',
              selected: mode == LiveWhen.schedule,
              onTap: () => controller.setWhen(LiveWhen.schedule),
            ),
          ),
        ],
      );
    });
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? ClientColors.primary
              : ClientColors.inputBg.withAlpha(120),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? ClientColors.primary : ClientColors.divider,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: ClientColors.primary.withAlpha(60),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? ClientColors.background
                : ClientColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Date picker ──────────────────────────────────────────────────────────────

class _DatePicker extends GetView<LiveRequestController> {
  const _DatePicker();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.dateOptions.length,
        separatorBuilder: (_, _) => 12.horizontalSpace,
        itemBuilder: (_, i) {
          return Obx(() {
            final date = controller.dateOptions[i];
            final selected =
                controller.selectedDate.value != null &&
                _isSameDay(controller.selectedDate.value!, date);
            return GestureDetector(
              onTap: () => controller.selectDate(date),
              child: _DateChip(date: date, index: i, selected: selected),
            );
          });
        },
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final int index;
  final bool selected;

  const _DateChip({
    required this.date,
    required this.index,
    required this.selected,
  });

  String get _topLabel {
    if (index == 0) return 'TODAY';
    if (index == 1) return 'TMRW';
    return DateFormat('EEE').format(date).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected
            ? accent.withAlpha(28)
            : ClientColors.inputBg.withAlpha(120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? accent : ClientColors.divider,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _topLabel,
            style: TextStyle(
              color: selected ? accent : ClientColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          4.verticalSpace,
          Text(
            DateFormat('d').format(date),
            style: TextStyle(
              color: selected ? accent : ClientColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          2.verticalSpace,
          Text(
            DateFormat('MMM').format(date).toUpperCase(),
            style: const TextStyle(
              color: ClientColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Time picker ──────────────────────────────────────────────────────────────

class _TimePicker extends GetView<LiveRequestController> {
  const _TimePicker();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: Obx(() {
        final _ = controller.selectedDate.value;
        final slots = controller.timeSlots;
        if (slots.isEmpty) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'No more slots today — pick another day.',
              style: TextStyle(color: ClientColors.textSecondary, fontSize: 13),
            ),
          );
        }
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: slots.length,
          separatorBuilder: (_, _) => 10.horizontalSpace,
          itemBuilder: (_, i) {
            return Obx(() {
              final slot = slots[i];
              final selected =
                  controller.selectedSlot.value != null &&
                  controller.selectedSlot.value!.isAtSameMomentAs(slot);
              return GestureDetector(
                onTap: () => controller.selectSlot(slot),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: selected
                        ? ClientColors.primary.withAlpha(28)
                        : ClientColors.inputBg.withAlpha(120),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected
                          ? ClientColors.primary
                          : ClientColors.divider,
                    ),
                  ),
                  child: Text(
                    DateFormat('HH:mm').format(slot),
                    style: TextStyle(
                      color: selected
                          ? ClientColors.primary
                          : ClientColors.textPrimary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            });
          },
        );
      }),
    );
  }
}

class _ScheduleSummary extends GetView<LiveRequestController> {
  const _ScheduleSummary();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final slot = controller.selectedSlot.value;
      if (slot == null) return const SizedBox.shrink();
      final text = DateFormat('EEE d MMM · HH:mm').format(slot);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: ClientColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ClientColors.primary.withAlpha(120)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: ClientColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            10.horizontalSpace,
            Text(
              'Scheduled for $text',
              style: const TextStyle(
                color: ClientColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ── Fee breakdown ────────────────────────────────────────────────────────────

class _FeeBreakdown extends GetView<LiveRequestController> {
  const _FeeBreakdown();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClientColors.inputBg.withAlpha(120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.divider.withAlpha(120)),
      ),
      child: Obx(() {
        // Touch reactive state so this rebuilds on tier / currency changes.
        controller.selectedTier.value;
        controller.displayCurrency.value;
        return Column(
          children: [
            _FeeRow(
              label: 'Session fee',
              value: controller.displayAmount(controller.sessionFee),
            ),
            12.verticalSpace,
            _FeeRow(
              label: 'Platform fee (20%)',
              value: controller.displayAmount(controller.platformFee),
            ),
            16.verticalSpace,
            Divider(color: ClientColors.divider.withAlpha(150), height: 1),
            16.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: ClientColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  controller.displayAmount(controller.total),
                  style: const TextStyle(
                    color: ClientColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _CurrencyToggle extends GetView<LiveRequestController> {
  const _CurrencyToggle();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: ClientColors.inputBg.withAlpha(120),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: Currency.values.map((c) {
            final selected = controller.displayCurrency.value == c;
            return GestureDetector(
              onTap: () => controller.setDisplayCurrency(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected ? ClientColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  c.code,
                  style: TextStyle(
                    color: selected
                        ? ClientColors.background
                        : ClientColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _LiveRateHint extends GetView<LiveRequestController> {
  const _LiveRateHint();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Text(
        'Live rate · 1 USD ≈ KSh ${controller.usdToKes.toInt().asCurrency}',
        style: const TextStyle(
          color: ClientColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  const _FeeRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ClientColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: ClientColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Submit bar ───────────────────────────────────────────────────────────────

class _SubmitBar extends GetView<LiveRequestController> {
  const _SubmitBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      child: Obx(
        () => SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: (controller.isSubmitting.value || !controller.hasPricing)
                ? null
                : controller.submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: ClientColors.primary,
              foregroundColor: ClientColors.background,
              disabledBackgroundColor: ClientColors.primary.withAlpha(80),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: controller.isSubmitting.value
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ClientColors.background,
                    ),
                  )
                : const Text(
                    'Send Request',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Shared ───────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: ClientColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

Color _availabilityColor(ScoutAvailability value) => switch (value) {
  ScoutAvailability.available => ClientColors.green,
  ScoutAvailability.bookable => ClientColors.primary,
  ScoutAvailability.offline => ClientColors.textSecondary,
};
