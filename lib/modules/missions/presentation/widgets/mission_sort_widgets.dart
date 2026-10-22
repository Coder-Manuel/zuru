import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zuru/config/scout_colors.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';

/// Compact "Nearest ▾" pill for the radar panel header. Opens a small sheet
/// of [MissionSort] options.
class MissionSortButton extends StatelessWidget {
  final MissionSort value;
  final ValueChanged<MissionSort> onChanged;

  const MissionSortButton({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showMissionSortSheet(context, value);
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
        decoration: BoxDecoration(
          color: ScoutColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ScoutColors.primary.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.swap_vert_rounded,
              size: 15,
              color: ScoutColors.textAccent,
            ),
            4.horizontalSpace,
            Text(
              value.label,
              style: const TextStyle(
                color: ScoutColors.textAccent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: ScoutColors.textAccent,
            ),
          ],
        ),
      ),
    );
  }
}

/// The sort options as a sheet; resolves to the picked one, or null.
Future<MissionSort?> showMissionSortSheet(
  BuildContext context,
  MissionSort current,
) {
  return showModalBottomSheet<MissionSort>(
    context: context,
    backgroundColor: ScoutColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          12.verticalSpace,
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ScoutColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'SORT LIVE CHECKS BY',
              style: TextStyle(
                color: ScoutColors.textAccent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          for (final option in MissionSort.values)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: Icon(
                _iconFor(option),
                color: option == current
                    ? ScoutColors.primary
                    : ScoutColors.textSecondary,
              ),
              title: Text(
                option.label,
                style: TextStyle(
                  color: ScoutColors.textPrimary,
                  fontWeight: option == current
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
              trailing: option == current
                  ? const Icon(Icons.check_rounded, color: ScoutColors.primary)
                  : null,
              onTap: () => Get.back(result: option),
            ),
          12.verticalSpace,
        ],
      ),
    ),
  );
}

/// Sort options as a scrollable chip row, for the Live Checks page header.
class MissionSortChips extends StatelessWidget {
  final MissionSort value;
  final ValueChanged<MissionSort> onChanged;

  const MissionSortChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: MissionSort.values.length,
        separatorBuilder: (_, _) => 8.horizontalSpace,
        itemBuilder: (_, i) {
          final option = MissionSort.values[i];
          final selected = option == value;
          return GestureDetector(
            onTap: () => onChanged(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? ScoutColors.primary : ScoutColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? ScoutColors.primary
                      : ScoutColors.primary.withAlpha(40),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconFor(option),
                    size: 15,
                    color: selected ? Colors.black : ScoutColors.textSecondary,
                  ),
                  6.horizontalSpace,
                  Text(
                    option.label,
                    style: TextStyle(
                      color: selected ? Colors.black : ScoutColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

IconData _iconFor(MissionSort sort) => switch (sort) {
  MissionSort.nearest => Icons.near_me_outlined,
  MissionSort.newest => Icons.schedule_rounded,
  MissionSort.highestPay => Icons.payments_outlined,
  MissionSort.shortest => Icons.timer_outlined,
};
