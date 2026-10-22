import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/domain/entities/mission.entity.dart';

/// Where the next `search_missions` page starts: the last row's sort key and
/// id.
class MissionPageCursor {
  final double sortKey;
  final String id;

  const MissionPageCursor({required this.sortKey, required this.id});
}

/// One page of the live-check pool.
class MissionPage {
  final List<MissionEntity> missions;

  /// Every pool mission within range, not just this page.
  final int totalCount;

  /// Null on the last page.
  final MissionPageCursor? nextCursor;

  const MissionPage({
    required this.missions,
    required this.totalCount,
    this.nextCursor,
  });

  bool get hasMore => nextCursor != null;
}

/// A pool change pushed on the `mission_pool` topic.
class MissionPoolEvent {
  final MissionPoolEventType type;
  final String id;
  final double? latitude;
  final double? longitude;

  const MissionPoolEvent({
    required this.type,
    required this.id,
    this.latitude,
    this.longitude,
  });
}
