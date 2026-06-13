import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zuru/config/client_colors.dart';
import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/utils/size.util.dart';
import 'package:zuru/modules/scouts/presentation/controllers/scouts_feed_controller.dart';
import 'package:zuru/modules/scouts/presentation/pages/scout_detail_page.dart';
import 'package:zuru/modules/scouts/presentation/widgets/scout_feed_card.dart';

class ScoutsFeedTab extends GetView<ScoutsFeedController> {
  const ScoutsFeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FeedHeader(),
            const _FilterChips(),
            16.verticalSpace,
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refreshFeed,
                color: ClientColors.primary,
                backgroundColor: ClientColors.inputBg,
                child: PagedListView<int, User>.separated(
                  pagingController: controller.pagingController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  separatorBuilder: (_, _) => 16.verticalSpace,
                  builderDelegate: PagedChildBuilderDelegate<User>(
                    itemBuilder: (_, scout, i) {
                      return ScoutFeedCard(
                            scout: scout,
                            onTap: () => Get.toNamed(
                              ScoutDetailPage.route,
                              arguments: scout.scoutProfile?.id,
                            ),
                          )
                          .animate(key: ValueKey(scout.scoutProfile?.id ?? i))
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.1, end: 0);
                    },
                    firstPageProgressIndicatorBuilder: (_) =>
                        const _FeedShimmer(),
                    newPageProgressIndicatorBuilder: (_) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ClientColors.primary,
                          ),
                        ),
                      ),
                    ),
                    noItemsFoundIndicatorBuilder: (_) => const _FeedEmpty(),
                    firstPageErrorIndicatorBuilder: (_) => _FeedError(
                      message: 'Could not load scouts',
                      onRetry: controller.pagingController.refresh,
                    ),
                    newPageErrorIndicatorBuilder: (_) => _RetryRow(
                      onRetry:
                          controller.pagingController.retryLastFailedRequest,
                    ),
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

// ── Header ───────────────────────────────────────────────────────────────────

class _FeedHeader extends GetView<ScoutsFeedController> {
  const _FeedHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scouts Feed',
                style: TextStyle(
                  color: ClientColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: ClientColors.primary.withAlpha(28),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ClientColors.primary.withAlpha(90)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: ClientColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    6.horizontalSpace,
                    const Text(
                      'GPS VERIFIED',
                      style: TextStyle(
                        color: ClientColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          6.verticalSpace,
          // Rebuild the counts whenever the paged list changes.
          ListenableBuilder(
            listenable: controller.pagingController,
            builder: (_, _) => RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: ClientColors.textSecondary,
                  fontSize: 13,
                ),
                children: [
                  TextSpan(text: '${controller.loadedCount} scouts found '),
                  const TextSpan(text: '· '),
                  TextSpan(
                    text: '${controller.liveCount} live now',
                    style: const TextStyle(
                      color: ClientColors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chips ─────────────────────────────────────────────────────────────

class _FilterChips extends GetView<ScoutsFeedController> {
  const _FilterChips();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: ScoutsFeedController.filters.length,
          separatorBuilder: (_, _) => 10.horizontalSpace,
          itemBuilder: (_, i) {
            return Obx(() {
              final filter = ScoutsFeedController.filters[i];
              final selected = controller.selectedFilterIndex.value == i;
              return GestureDetector(
                onTap: () => controller.selectFilter(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
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
                    filter.label,
                    style: TextStyle(
                      color: selected
                          ? ClientColors.primary
                          : ClientColors.textPrimary,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }
}

// ── States ───────────────────────────────────────────────────────────────────

class _FeedShimmer extends StatelessWidget {
  const _FeedShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: ClientColors.inputBg,
      highlightColor: ClientColors.divider,
      child: Column(
        children: List.generate(
          4,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 200,
            decoration: BoxDecoration(
              color: ClientColors.inputBg,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedEmpty extends StatelessWidget {
  const _FeedEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: const [
          Icon(
            Icons.travel_explore_rounded,
            color: ClientColors.textSecondary,
            size: 56,
          ),
          SizedBox(height: 16),
          Text(
            'No scouts match this filter',
            style: TextStyle(color: ClientColors.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FeedError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: ClientColors.textSecondary,
            size: 48,
          ),
          16.verticalSpace,
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ClientColors.textSecondary,
              fontSize: 14,
            ),
          ),
          20.verticalSpace,
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: ClientColors.primary,
              side: const BorderSide(color: ClientColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _RetryRow extends StatelessWidget {
  final VoidCallback onRetry;
  const _RetryRow({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: TextButton(
          onPressed: onRetry,
          child: const Text(
            'Tap to retry',
            style: TextStyle(color: ClientColors.primary),
          ),
        ),
      ),
    );
  }
}
