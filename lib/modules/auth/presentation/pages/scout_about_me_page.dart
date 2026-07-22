import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/auth/presentation/controllers/register_controller.dart';
import 'package:zuru/modules/auth/presentation/widgets/auth_widgets.dart';

/// Pre-defined skill / expertise tags a scout can attach to their profile.
const _kAvailableTags = [
  'Security',
  'Surveillance',
  'Investigation',
  'Real Estate',
  'Legal',
  'Insurance',
  'Media',
  'Corporate',
  'Event Monitoring',
  'Traffic',
  'Environmental',
  'Sports',
  'Aviation',
  'Marine',
  'Retail',
];

class ScoutAboutMePage extends GetView<RegisterController> {
  static const String route = '/scout/about-me';

  const ScoutAboutMePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color;
    final fillColor = Theme.of(context).inputDecorationTheme.fillColor;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              24.verticalSpace,

              // ── Heading ────────────────────────────────────────────────────
              Text(
                'About You',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              10.verticalSpace,
              Text(
                'Help viewers understand what makes you the right guide for their live check.',
                style: TextStyle(color: bodyColor, fontSize: 15, height: 1.5),
              ),

              32.verticalSpace,

              // ── Bio ────────────────────────────────────────────────────────
              Text(
                'BIO',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              8.verticalSpace,
              _BioField(
                controller: controller.bioCTRL,
                fillColor: fillColor,
                textColor: scheme.onSurface,
                hintColor: bodyColor,
                primaryColor: scheme.primary,
              ),

              28.verticalSpace,

              // ── Tags ───────────────────────────────────────────────────────
              Text(
                'SKILLS & EXPERTISE',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              6.verticalSpace,
              Text(
                'Select all that apply.',
                style: TextStyle(color: bodyColor, fontSize: 13),
              ),
              14.verticalSpace,
              Obx(
                () => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kAvailableTags.map((tag) {
                    final selected = controller.selectedTags.contains(tag);
                    return _TagChip(
                      label: tag,
                      selected: selected,
                      selectedColor: scheme.primary,
                      onTap: () => controller.toggleTag(tag),
                    );
                  }).toList(),
                ),
              ),

              40.verticalSpace,

              // ── Submit ─────────────────────────────────────────────────────
              PrimaryButton(
                label: 'Complete Profile',
                onPressed: controller.updateScoutProfile,
              ),

              32.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bio text field ─────────────────────────────────────────────────────────────

class _BioField extends StatefulWidget {
  final TextEditingController controller;
  final Color? fillColor;
  final Color textColor;
  final Color? hintColor;
  final Color primaryColor;

  const _BioField({
    required this.controller,
    required this.fillColor,
    required this.textColor,
    required this.hintColor,
    required this.primaryColor,
  });

  @override
  State<_BioField> createState() => _BioFieldState();
}

class _BioFieldState extends State<_BioField> {
  static const int _maxChars = 200;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final remaining = _maxChars - widget.controller.text.length;
    final overLimit = remaining < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: widget.controller,
          maxLines: 4,
          maxLength: _maxChars,
          buildCounter:
              (_, {required currentLength, required isFocused, maxLength}) =>
                  const SizedBox.shrink(), // we draw our own counter below
          style: TextStyle(color: widget.textColor, fontSize: 15, height: 1.5),
          decoration: InputDecoration(
            hintText:
                'e.g. Experienced surveillance operative with 5 years in corporate security...',
            hintStyle: TextStyle(
              color: widget.hintColor,
              fontSize: 14,
              height: 1.5,
            ),
            filled: true,
            fillColor: widget.fillColor,
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
              borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.controller.text.length} / $_maxChars',
          style: TextStyle(
            color: overLimit ? Colors.redAccent : widget.hintColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── Tag chip ───────────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color;
    final fillColor = Theme.of(context).inputDecorationTheme.fillColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? selectedColor.withAlpha(30) : fillColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? selectedColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 14, color: selectedColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? selectedColor : bodyColor,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
