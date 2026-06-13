import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:zuru/core/entities/user.entity.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/modules/scouts/domain/usecases/get_scouts_feed.usecase.dart';

enum ScoutFilterKind { all, available, tag }

/// A single horizontal filter chip in the feed.
class ScoutFilter {
  final String label;
  final ScoutFilterKind kind;
  final String? tag;

  const ScoutFilter(this.label, this.kind, [this.tag]);
}

class ScoutsFeedController extends GetxController {
  final GetScoutsFeedUseCase _getScoutsFeed;

  ScoutsFeedController({required GetScoutsFeedUseCase getScoutsFeed})
    : _getScoutsFeed = getScoutsFeed;

  static const int pageSize = 10;

  /// Fixed filter set. "Available Now" filters by availability; the rest are
  /// tag filters.
  static const List<ScoutFilter> filters = [
    ScoutFilter('All', ScoutFilterKind.all),
    ScoutFilter('Available Now', ScoutFilterKind.available),
    ScoutFilter('Markets', ScoutFilterKind.tag, 'Markets'),
    ScoutFilter('Real Estate', ScoutFilterKind.tag, 'Real Estate'),
    ScoutFilter('Technology', ScoutFilterKind.tag, 'Technology'),
    ScoutFilter('Tourism', ScoutFilterKind.tag, 'Tourism'),
    ScoutFilter('Cultural Tours', ScoutFilterKind.tag, 'Cultural Tours'),
  ];

  final RxInt selectedFilterIndex = 0.obs;

  /// Drives the `infinite_scroll_pagination` list.
  final PagingController<int, User> pagingController = PagingController(
    firstPageKey: 0,
  );

  ScoutFilter get _selected => filters[selectedFilterIndex.value];

  List<User> get _items => pagingController.itemList ?? const [];

  /// Count of currently-loaded scouts that are live (available).
  int get loadedCount => _items.length;
  int get liveCount => _items
      .where((u) => u.scoutProfile?.availability == ScoutAvailability.available)
      .length;

  @override
  void onInit() {
    super.onInit();
    pagingController.addPageRequestListener(_fetchPage);
  }

  @override
  void onClose() {
    pagingController.dispose();
    super.onClose();
  }

  Future<void> _fetchPage(int pageKey) async {
    final filter = _selected;
    final result = await _getScoutsFeed(
      ScoutsFeedParams(
        page: pageKey,
        pageSize: pageSize,
        availableOnly: filter.kind == ScoutFilterKind.available,
        tag: filter.kind == ScoutFilterKind.tag ? filter.tag : null,
      ),
    );

    result.fold((err) => pagingController.error = err.message, (items) {
      final isLastPage = items.length < pageSize;
      if (isLastPage) {
        pagingController.appendLastPage(items);
      } else {
        pagingController.appendPage(items, pageKey + 1);
      }
    });
  }

  void selectFilter(int index) {
    if (index == selectedFilterIndex.value) return;
    selectedFilterIndex.value = index;
    pagingController.refresh();
  }

  Future<void> refreshFeed() async => pagingController.refresh();
}
