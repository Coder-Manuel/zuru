import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/core/utils/size.util.dart';

/// Shimmer placeholder that mirrors the scout profile layout while the detail
/// API call is in flight.
class ScoutDetailSkeleton extends StatelessWidget {
  const ScoutDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: ClientColors.inputBg,
      highlightColor: ClientColors.divider,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top bar
            Row(
              children: [
                _box(44, 44, radius: 22),
                16.horizontalSpace,
                _box(120, 14),
              ],
            ),
            24.verticalSpace,
            _box(150, 150, radius: 75),
            20.verticalSpace,
            _box(200, 26),
            12.verticalSpace,
            _box(140, 14),
            20.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _box(110, 38, radius: 20),
                12.horizontalSpace,
                _box(110, 38, radius: 20),
                12.horizontalSpace,
                _box(70, 38, radius: 20),
              ],
            ),
            28.verticalSpace,
            Align(alignment: Alignment.centerLeft, child: _box(160, 12)),
            14.verticalSpace,
            Row(
              children: [
                Expanded(child: _box(0, 120, radius: 14)),
                12.horizontalSpace,
                Expanded(child: _box(0, 120, radius: 14)),
                12.horizontalSpace,
                Expanded(child: _box(0, 120, radius: 14)),
              ],
            ),
            20.verticalSpace,
            _box(double.infinity, 120, radius: 16),
            20.verticalSpace,
            _box(double.infinity, 150, radius: 16),
            24.verticalSpace,
            _box(double.infinity, 56, radius: 16),
          ],
        ),
      ),
    );
  }

  Widget _box(double w, double h, {double radius = 6}) {
    return Container(
      width: w == 0 ? null : w,
      height: h,
      decoration: BoxDecoration(
        color: ClientColors.inputBg,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
