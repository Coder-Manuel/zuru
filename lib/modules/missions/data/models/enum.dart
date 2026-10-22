enum MissionStatus {
  open,
  requested,
  declined,
  accepted,
  enroute,
  live,
  completed,
  cancelled,
}

enum MissionType {
  surveillance,
  intelGathering,
  perimeterCheck,
  extractionSupport,
  eventVerification,
  customTask,

  /// A client-initiated live session request targeted at a specific scout.
  liveRequest;

  String get label => switch (this) {
    MissionType.surveillance => 'Live Site Check',
    MissionType.intelGathering => 'Location Insight',
    MissionType.perimeterCheck => 'Perimeter Check',
    MissionType.extractionSupport => 'Extraction Support',
    MissionType.eventVerification => 'Event Verification',
    MissionType.customTask => 'Custom Task',
    MissionType.liveRequest => 'Live Request',
  };

  String get apiValue => switch (this) {
    MissionType.surveillance => 'surveillance',
    MissionType.intelGathering => 'intel_gathering',
    MissionType.perimeterCheck => 'perimeter_check',
    MissionType.extractionSupport => 'extraction_support',
    MissionType.eventVerification => 'event_verification',
    MissionType.customTask => 'custom_task',
    MissionType.liveRequest => 'live_request',
  };
}

/// What `decline_mission` did: a live request is declined, a pool mission is
/// released back to the board.
enum DeclineOutcome {
  declined,
  released;

  static DeclineOutcome fromApi(String? value) =>
      value == 'released' ? DeclineOutcome.released : DeclineOutcome.declined;
}

/// How the scout orders the live-check pool. [apiValue] is `search_missions`'
/// `p_sort`.
enum MissionSort {
  nearest,
  newest,
  highestPay,
  shortest;

  String get label => switch (this) {
    MissionSort.nearest => 'Nearest',
    MissionSort.newest => 'Newest',
    MissionSort.highestPay => 'Highest pay',
    MissionSort.shortest => 'Shortest',
  };

  String get apiValue => switch (this) {
    MissionSort.nearest => 'distance',
    MissionSort.newest => 'newest',
    MissionSort.highestPay => 'pay_desc',
    MissionSort.shortest => 'duration_asc',
  };

  static MissionSort fromName(String? name) => MissionSort.values.firstWhere(
    (v) => v.name == name,
    orElse: () => MissionSort.nearest,
  );
}

/// A change to the pool pushed on the `mission_pool` broadcast topic.
enum MissionPoolEventType {
  added,
  updated,
  removed;

  static MissionPoolEventType? fromApi(String? value) {
    for (final v in MissionPoolEventType.values) {
      if (v.name == value) return v;
    }
    return null;
  }
}
