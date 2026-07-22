import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/core/services/fx_service/fx_service.dart';
import 'package:zuru/core/utils/extensions.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/core/widgets/custom_dropdown.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/presentation/controllers/post_mission_controller.dart';

class PostMissionPage extends GetView<PostMissionController> {
  static const String route = '/post-mission';

  const PostMissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  _CircleBackButton(),
                  const SizedBox(width: 14),
                  Text(
                    'Post a Live Check',
                    style: TextStyle(
                      color: ClientColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            16.verticalSpace,

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── GPS banner (tappable — opens location picker) ─────
                      Obx(
                        () => _GpsBanner(
                          location: controller.address.value,
                          hasLocation: controller.hasLocation.value,
                          onTap: controller.openLocationPicker,
                        ),
                      ),
                      24.verticalSpace,

                      // ── Mission type ──────────────────────────────────────
                      _FieldLabel('LIVE CHECK TYPE'),
                      6.verticalSpace,
                      Obx(
                        () => CustomDropDown<MissionType>(
                          hint: 'Select live check type',
                          value: controller.selectedMissionType.value,
                          items: controller.missionTypes,
                          itemLabel: (v) => v.label,
                          prefixIcon: Icons.radar_outlined,
                          onChanged: (v) =>
                              controller.selectedMissionType.value = v,
                          validator: (v) =>
                              v == null ? 'Select a live check type' : null,
                        ),
                      ),
                      20.verticalSpace,

                      // ── Instructions to scout (description) ──────────────
                      _FieldLabel('INSTRUCTIONS TO GUIDE'),
                      6.verticalSpace,
                      _MissionTextField(
                        controller: controller.descriptionCTRL,
                        keyboardType: TextInputType.text,
                        hint:
                            'e.g. Walk the block and show me the main gate...',
                        maxLines: 4,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Enter instructions'
                            : null,
                      ),
                      20.verticalSpace,

                      // ── Duration (minutes) ────────────────────────────────
                      _FieldLabel('DURATION (MINUTES)'),
                      6.verticalSpace,
                      Obx(
                        () => CustomDropDown<int>(
                          hint: 'Select duration',
                          value: controller.selectedDuration.value,
                          items: controller.durations,
                          itemLabel: (v) => '$v min',
                          prefixIcon: Icons.timer_outlined,
                          onChanged: controller.selectDuration,
                          validator: (v) =>
                              v == null ? 'Select a duration' : null,
                        ),
                      ),
                      20.verticalSpace,

                      // ── Offer price ───────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _FieldLabel('OFFER PRICE'),
                          const _CurrencyToggle(),
                        ],
                      ),
                      12.verticalSpace,
                      Obx(() {
                        final options = controller.priceOptions;
                        if (options.isEmpty) {
                          return const _PriceHint();
                        }
                        return Row(
                          children: List.generate(
                            options.length,
                            (i) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: i < options.length - 1 ? 10 : 0,
                                ),
                                child: _PriceChip(
                                  label: controller.priceLabel(options[i]),
                                  selected:
                                      controller.selectedPriceIndex.value == i,
                                  onTap: () => controller.selectPrice(i),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      // Live FX hint (KES only).
                      Obx(() {
                        if (controller.currency.value != Currency.kes) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'Live rate · 1 USD ≈ KSh '
                            '${controller.usdToKes.toInt().asCurrency}',
                            style: TextStyle(
                              color: ClientColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }),
                      32.verticalSpace,

                      // ── Post button ───────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: () => controller.postMission(formKey),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ClientColors.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Text(
                            'Post Live Check  →',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      32.verticalSpace,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── GPS Banner ───────────────────────────────────────────────────────────────

class _GpsBanner extends StatelessWidget {
  final String location;
  final bool hasLocation;
  final VoidCallback onTap;

  const _GpsBanner({
    required this.location,
    required this.hasLocation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasLocation ? Color(0xFF1E1A0E) : ClientColors.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasLocation
                ? ClientColors.primary.withAlpha(60)
                : ClientColors.divider.withAlpha(80),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              hasLocation ? '📍' : '🗺️',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasLocation
                    ? '$location · GPS confirmed'
                    : 'Tap to set live check location',
                style: TextStyle(
                  color: hasLocation
                      ? ClientColors.primary
                      : ClientColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: hasLocation
                  ? ClientColors.primary
                  : ClientColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Field label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: ClientColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

// ─── Mission text field ───────────────────────────────────────────────────────

class _MissionTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _MissionTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: ClientColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: ClientColors.textSecondary, fontSize: 15),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

// ─── Price chip ───────────────────────────────────────────────────────────────

class _PriceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PriceChip({
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
        height: 48,
        decoration: BoxDecoration(
          color: selected
              ? ClientColors.primary.withAlpha(25)
              : ClientColors.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? ClientColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: selected
                  ? ClientColors.primary
                  : ClientColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Currency toggle ──────────────────────────────────────────────────────────

class _CurrencyToggle extends StatelessWidget {
  const _CurrencyToggle();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PostMissionController>();
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: ClientColors.inputBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: Currency.values.map((c) {
            final selected = controller.currency.value == c;
            return GestureDetector(
              onTap: () => controller.setCurrency(c),
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
                    color: selected ? Colors.black : ClientColors.textSecondary,
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

// ─── Price hint (no duration yet) ─────────────────────────────────────────────

class _PriceHint extends StatelessWidget {
  const _PriceHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ClientColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ClientColors.divider.withAlpha(80)),
      ),
      child: Text(
        'Select a duration to see offer prices',
        style: TextStyle(
          color: ClientColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Circle back button ───────────────────────────────────────────────────────

class _CircleBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: ClientColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back,
          color: ClientColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}
