import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:zuru/core/entities/profile_clip.entity.dart';
import 'package:zuru/core/entities/session_pricing.entity.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/core/widgets/app_cached_image.dart';
import 'package:zuru/core/widgets/reels_player_page.dart';
import 'package:zuru/core/widgets/video_thumbnail_view.dart';
import 'package:zuru/modules/user/presentation/controllers/scout_profile_edit_controller.dart';
import 'package:zuru/modules/user/presentation/widgets/locality_search_sheet.dart';

/// Preset tag suggestions shown on the World Profile editor.
const _kPresetTags = [
  'Real Estate',
  'Technology',
  'Automotive',
  'Agriculture',
  'Tourism',
  'Education',
  'Entertainment',
];

class ScoutProfileEditPage extends GetView<ScoutProfileEditController> {
  static const String route = '/scout/profile/edit';

  const ScoutProfileEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color;
    final fillColor = Theme.of(context).inputDecorationTheme.fillColor;

    // Staggered slide-in: each section fades + slides up, offset by its order.
    var step = 0;
    Widget animate(Widget child) {
      final delay = (step++ * 70).ms;
      return child
          .animate()
          .fadeIn(delay: delay, duration: 450.ms)
          .slideY(begin: 0.12, end: 0, delay: delay, duration: 450.ms);
    }

    Widget section(String label, Widget content, {Widget? header}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header ?? _SectionLabel(label, color: bodyColor),
          10.verticalSpace,
          content,
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              16.verticalSpace,
              animate(_Header(scheme: scheme)),
              24.verticalSpace,

              animate(
                _PreviewCard(
                  scheme: scheme,
                  bodyColor: bodyColor,
                  fillColor: fillColor,
                ),
              ),
              28.verticalSpace,

              animate(
                section(
                  'PROFILE CLIPS (3 MAX)',
                  _ClipsRow(scheme: scheme, bodyColor: bodyColor),
                ),
              ),
              28.verticalSpace,

              animate(
                section(
                  'YOUR BIO · YOUR WORDS',
                  _BioField(
                    scheme: scheme,
                    bodyColor: bodyColor,
                    fillColor: fillColor,
                  ),
                ),
              ),
              28.verticalSpace,

              animate(
                section(
                  '',
                  _TagsSection(
                    scheme: scheme,
                    bodyColor: bodyColor,
                    fillColor: fillColor,
                  ),
                  header: _TagsHeader(bodyColor: bodyColor),
                ),
              ),
              28.verticalSpace,

              animate(
                section(
                  'AVAILABILITY STATUS',
                  _AvailabilityRow(
                    scheme: scheme,
                    bodyColor: bodyColor,
                    fillColor: fillColor,
                  ),
                ),
              ),
              28.verticalSpace,

              animate(
                section(
                  'MY SESSION PRICING',
                  _PricingSection(
                    scheme: scheme,
                    bodyColor: bodyColor,
                    fillColor: fillColor,
                  ),
                ),
              ),
              32.verticalSpace,

              animate(_SaveButton(scheme: scheme)),
              24.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final ColorScheme scheme;
  const _Header({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final fillColor = Theme.of(context).inputDecorationTheme.fillColor;
    return Row(
      children: [
        GestureDetector(
          onTap: Get.back,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: fillColor, shape: BoxShape.circle),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: scheme.onSurface,
              size: 18,
            ),
          ),
        ),
        16.horizontalSpace,
        Text(
          'My World Profile',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

// ── Preview card ────────────────────────────────────────────────────────────────

class _PreviewCard extends GetView<ScoutProfileEditController> {
  final ColorScheme scheme;
  final Color? bodyColor;
  final Color? fillColor;

  const _PreviewCard({
    required this.scheme,
    required this.bodyColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUserName;
    final rating = controller.rating;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: fillColor?.withAlpha(178),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR PROFILE PREVIEW',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Obx(
                () => _AvailabilityPill(value: controller.availability.value),
              ),
            ],
          ),
          10.verticalSpace,
          Row(
            children: [
              _AvatarPicker(controller: controller, scheme: scheme),
              14.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    6.verticalSpace,
                    GestureDetector(
                      onTap: () => _openLocalitySheet(context),
                      child: Obx(
                        () => Row(
                          children: [
                            Icon(
                              Icons.place_rounded,
                              size: 15,
                              color: scheme.primary,
                            ),
                            4.horizontalSpace,
                            Flexible(
                              child: Text(
                                controller.locality.value?.isNotEmpty == true
                                    ? controller.locality.value!
                                    : 'Add location',
                                style: TextStyle(
                                  color: bodyColor,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                  decorationColor: bodyColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            8.horizontalSpace,
                            Text(
                              '· $rating',
                              style: TextStyle(color: bodyColor, fontSize: 13),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFC107),
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openLocalitySheet(BuildContext context) {
    showLocalitySearchSheet(context);
  }
}

class _AvatarPicker extends StatelessWidget {
  final ScoutProfileEditController controller;
  final ColorScheme scheme;
  const _AvatarPicker({required this.controller, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final fillColor = Theme.of(context).inputDecorationTheme.fillColor;
    return GestureDetector(
      onTap: controller.pickAvatar,
      child: Obx(() {
        final file = controller.pickedAvatar.value;
        final url = controller.avatarUrl.value;
        final name = controller.currentUserName;

        final initials = Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'S',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        );

        Widget avatarContent;
        if (file != null) {
          avatarContent = Image.file(file, fit: BoxFit.cover);
        } else if (url != null && url.isNotEmpty) {
          avatarContent = AppCachedImage(url: url, fallback: initials);
        } else {
          avatarContent = initials;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fillColor,
                border: Border.all(color: scheme.primary, width: 2),
              ),
              child: ClipOval(child: avatarContent),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 2),
                ),
                child: const Icon(Icons.edit, size: 11, color: Colors.black),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  final ScoutAvailability value;
  const _AvailabilityPill({required this.value});

  @override
  Widget build(BuildContext context) {
    final color = _availabilityColor(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Text(
        value.label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Profile clips ────────────────────────────────────────────────────────────────

/// A flat row of up to [ScoutProfileEditController.maxClips] clip slots:
/// filled clips first, then a single "Add Clip" tile, then faint placeholders
/// showing remaining capacity.
class _ClipsRow extends GetView<ScoutProfileEditController> {
  final ColorScheme scheme;
  final Color? bodyColor;

  const _ClipsRow({required this.scheme, required this.bodyColor});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final clips = controller.clips;
      final count = clips.length;
      const max = ScoutProfileEditController.maxClips;

      return Row(
        children: List.generate(max, (i) {
          final isLast = i == max - 1;

          Widget tile;
          if (i < count) {
            tile = _FilledClipTile(
              key: ValueKey(clips[i].id ?? clips[i].mediaUrl),
              mediaUrl: clips[i].mediaUrl ?? '',
              index: i,
              onTap: () => _playClips(clips, i),
              onRemove: () => controller.removeClip(clips[i]),
            );
          } else if (i == count) {
            tile = _AddClipTile(
              scheme: scheme,
              isUploading: controller.isAddingClip.value,
              onTap: controller.addClip,
            );
          } else {
            tile = _EmptyClipTile(bodyColor: bodyColor);
          }

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 12),
              child: AspectRatio(aspectRatio: 0.92, child: tile),
            ),
          );
        }),
      );
    });
  }

  void _playClips(List<ProfileClip> clips, int index) {
    final urls = clips
        .map((c) => c.mediaUrl)
        .whereType<String>()
        .where((u) => u.isNotEmpty)
        .toList();
    if (urls.isEmpty) return;
    final titles = clips
        .map((c) => (c.title?.isNotEmpty ?? false) ? c.title! : 'Clip')
        .toList();
    ReelsPlayerPage.open(urls, initialIndex: index, titles: titles);
  }
}

class _FilledClipTile extends StatelessWidget {
  final String mediaUrl;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FilledClipTile({
    super.key,
    required this.mediaUrl,
    required this.index,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: VideoThumbnailView(
              url: mediaUrl,
              borderRadius: BorderRadius.circular(14),
              playIconSize: 34,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(150),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 8,
            child: Text(
              'CLIP ${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddClipTile extends StatelessWidget {
  final ColorScheme scheme;
  final bool isUploading;
  final VoidCallback onTap;

  const _AddClipTile({
    required this.scheme,
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: scheme.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.primary.withAlpha(110), width: 1.4),
        ),
        child: Center(
          child: isUploading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: scheme.primary.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: scheme.primary,
                        size: 22,
                      ),
                    ),
                    8.verticalSpace,
                    Text(
                      'ADD CLIP',
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _EmptyClipTile extends StatelessWidget {
  final Color? bodyColor;
  const _EmptyClipTile({required this.bodyColor});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: bodyColor?.withAlpha(45) ?? Colors.grey,
          width: 1.4,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: bodyColor?.withAlpha(70),
          size: 22,
        ),
      ),
    );
  }
}

// ── Bio ────────────────────────────────────────────────────────────────────────

class _BioField extends StatefulWidget {
  final ColorScheme scheme;
  final Color? bodyColor;
  final Color? fillColor;

  const _BioField({
    required this.scheme,
    required this.bodyColor,
    required this.fillColor,
  });

  @override
  State<_BioField> createState() => _BioFieldState();
}

class _BioFieldState extends State<_BioField> {
  final controller = Get.find<ScoutProfileEditController>();

  @override
  void initState() {
    super.initState();
    controller.bioCTRL.addListener(_onChanged);
  }

  @override
  void dispose() {
    controller.bioCTRL.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final length = controller.bioCTRL.text.length;
    return Container(
      decoration: BoxDecoration(
        // color: widget.fillColor?.withAlpha(178),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: controller.bioCTRL,
            maxLines: 4,
            maxLength: ScoutProfileEditController.maxBioChars,
            buildCounter:
                (_, {required currentLength, required isFocused, maxLength}) =>
                    const SizedBox.shrink(),
            style: TextStyle(
              color: widget.scheme.onSurface,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Tell viewers what you show them about your world…',
              hintStyle: TextStyle(color: widget.bodyColor, fontSize: 13),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(6),
            ),
          ),
          Text(
            '$length / ${ScoutProfileEditController.maxBioChars}',
            style: TextStyle(color: widget.bodyColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Tags ─────────────────────────────────────────────────────────────────────────

class _TagsHeader extends GetView<ScoutProfileEditController> {
  final Color? bodyColor;
  const _TagsHeader({required this.bodyColor});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SectionLabel(
          'YOUR TAGS (${ScoutProfileEditController.maxTags} MAX)',
          color: bodyColor,
        ),
        Obx(
          () => Text(
            '${controller.selectedTags.length} / ${ScoutProfileEditController.maxTags}',
            style: TextStyle(
              color: scheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TagsSection extends GetView<ScoutProfileEditController> {
  final ColorScheme scheme;
  final Color? bodyColor;
  final Color? fillColor;

  const _TagsSection({
    required this.scheme,
    required this.bodyColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fillColor?.withAlpha(178),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected tags
          Obx(() {
            if (controller.selectedTags.isEmpty) {
              return Text(
                'No tags yet — pick from suggestions below.',
                style: TextStyle(color: bodyColor, fontSize: 13),
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.selectedTags
                  .map(
                    (tag) => _SelectedTagChip(
                      label: tag,
                      color: scheme.primary,
                      onRemove: () => controller.removeTag(tag),
                    ),
                  )
                  .toList(),
            );
          }),
          16.verticalSpace,
          Divider(color: bodyColor?.withAlpha(40), height: 1),
          16.verticalSpace,
          Text(
            'PRESET SUGGESTIONS',
            style: TextStyle(
              color: bodyColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          12.verticalSpace,
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kPresetTags.map((tag) {
                final selected = controller.selectedTags.contains(tag);
                return _PresetTagChip(
                  label: tag,
                  selected: selected,
                  color: scheme.primary,
                  bodyColor: bodyColor,
                  onTap: () => controller.toggleTag(tag),
                );
              }).toList(),
            ),
          ),
          16.verticalSpace,
          Divider(color: bodyColor?.withAlpha(40), height: 1),
          14.verticalSpace,
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.customTagCTRL,
                  style: TextStyle(color: scheme.onSurface, fontSize: 13),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => controller.addCustomTag(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Type custom tag…',
                    hintStyle: TextStyle(color: bodyColor, fontSize: 13),
                    filled: true,
                    fillColor: scheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              12.horizontalSpace,
              GestureDetector(
                onTap: controller.addCustomTag,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Add',
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedTagChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onRemove;

  const _SelectedTagChip({
    required this.label,
    required this.color,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          8.horizontalSpace,
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 15, color: color),
          ),
        ],
      ),
    );
  }
}

class _PresetTagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final Color? bodyColor;
  final VoidCallback onTap;

  const _PresetTagChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.bodyColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color : scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : (bodyColor?.withAlpha(60) ?? Colors.grey),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_rounded : Icons.add_rounded,
              size: 14,
              color: selected ? Colors.black : bodyColor,
            ),
            4.horizontalSpace,
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : bodyColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Availability ──────────────────────────────────────────────────────────────────

class _AvailabilityRow extends GetView<ScoutProfileEditController> {
  final ColorScheme scheme;
  final Color? bodyColor;
  final Color? fillColor;

  const _AvailabilityRow({
    required this.scheme,
    required this.bodyColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: ScoutAvailability.values.map((value) {
          final selected = controller.availability.value == value;
          final color = _availabilityColor(value);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: value == ScoutAvailability.values.last ? 0 : 12,
              ),
              child: GestureDetector(
                onTap: () => controller.setAvailability(value),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: fillColor?.withAlpha(178),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? color : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: color.withAlpha(60),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      8.horizontalSpace,
                      Text(
                        value.label,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Session pricing ──────────────────────────────────────────────────────────────

class _PricingSection extends GetView<ScoutProfileEditController> {
  final ColorScheme scheme;
  final Color? bodyColor;
  final Color? fillColor;

  const _PricingSection({
    required this.scheme,
    required this.bodyColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          ...controller.sessionPricing.map(
            (tier) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PricingRow(
                tier: tier,
                scheme: scheme,
                bodyColor: bodyColor,
                fillColor: fillColor,
                onRemove: () => controller.removePricing(tier),
              ),
            ),
          ),
          if (controller.showAddPricing.value)
            _AddPricingForm(
              scheme: scheme,
              bodyColor: bodyColor,
              fillColor: fillColor,
            )
          else
            _AddPricingButton(
              bodyColor: bodyColor,
              onTap: controller.openAddPricing,
            ),
        ],
      ),
    );
  }
}

class _PricingRow extends StatelessWidget {
  final SessionPricing tier;
  final ColorScheme scheme;
  final Color? bodyColor;
  final Color? fillColor;
  final VoidCallback onRemove;

  const _PricingRow({
    required this.tier,
    required this.scheme,
    required this.bodyColor,
    required this.fillColor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: fillColor?.withAlpha(178),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tier.label,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            tier.currency,
            style: TextStyle(
              color: scheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          16.horizontalSpace,
          Text(
            '${tier.price}',
            style: TextStyle(
              color: scheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          12.horizontalSpace,
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPricingButton extends StatelessWidget {
  final Color? bodyColor;
  final VoidCallback onTap;
  const _AddPricingButton({required this.bodyColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: bodyColor?.withAlpha(70) ?? Colors.grey,
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: bodyColor, size: 18),
            8.horizontalSpace,
            Text(
              'ADD SESSION PRICING',
              style: TextStyle(
                color: bodyColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPricingForm extends GetView<ScoutProfileEditController> {
  final ColorScheme scheme;
  final Color? bodyColor;
  final Color? fillColor;

  const _AddPricingForm({
    required this.scheme,
    required this.bodyColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fillColor?.withAlpha(178),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bodyColor?.withAlpha(50) ?? Colors.grey),
      ),
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
                    _MiniLabel('SELECT DURATION', color: bodyColor),
                    8.verticalSpace,
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: controller.newDuration.value,
                            dropdownColor: scheme.surface,
                            iconEnabledColor: bodyColor,
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontSize: 14,
                            ),
                            items: controller.availableDurations
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text('$d min session'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => controller.newDuration.value = v,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              16.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MiniLabel('PRICE (KES)', color: bodyColor),
                    8.verticalSpace,
                    TextField(
                      controller: controller.priceCTRL,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: scheme.onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'e.g. 1500',
                        hintStyle: TextStyle(color: bodyColor, fontSize: 14),
                        filled: true,
                        fillColor: scheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          16.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: controller.cancelAddPricing,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: bodyColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              8.horizontalSpace,
              GestureDetector(
                onTap: controller.confirmAddPricing,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Confirm Add',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Footer buttons ────────────────────────────────────────────────────────────────

class _SaveButton extends GetView<ScoutProfileEditController> {
  final ColorScheme scheme;
  const _SaveButton({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 45,
        child: ElevatedButton(
          onPressed: controller.isSaving.value ? null : controller.save,
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: controller.isSaving.value
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text(
                  'Save Profile',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}

// class _PreviewButton extends GetView<ScoutProfileEditController> {
//   final ColorScheme scheme;
//   final Color? fillColor;

//   const _PreviewButton({required this.scheme, required this.fillColor});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: double.infinity,
//       height: 45,
//       child: TextButton(
//         onPressed: controller.previewAsClient,
//         style: TextButton.styleFrom(
//           backgroundColor: fillColor?.withAlpha(178),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//         ),
//         child: Text(
//           'Preview as Client',
//           style: TextStyle(
//             color: scheme.onSurface,
//             fontSize: 16,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//     );
//   }
// }

// ── Shared bits ────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;
  const _SectionLabel(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  final String text;
  final Color? color;
  const _MiniLabel(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }
}

Color _availabilityColor(ScoutAvailability value) => switch (value) {
  ScoutAvailability.available => const Color(0xFF3DFF6B),
  ScoutAvailability.bookable => const Color(0xFFF5A020),
  ScoutAvailability.offline => const Color(0xFF8A8F98),
};
