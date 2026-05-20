enum MissionStatus { open, accepted, enroute, live, completed, cancelled }

enum MissionType {
  surveillance,
  intelGathering,
  perimeterCheck,
  extractionSupport,
  eventVerification,
  customTask;

  String get label => switch (this) {
    MissionType.surveillance => 'Surveillance',
    MissionType.intelGathering => 'Intel Gathering',
    MissionType.perimeterCheck => 'Perimeter Check',
    MissionType.extractionSupport => 'Extraction Support',
    MissionType.eventVerification => 'Event Verification',
    MissionType.customTask => 'Custom Task',
  };

  String get apiValue => switch (this) {
    MissionType.surveillance => 'surveillance',
    MissionType.intelGathering => 'intel_gathering',
    MissionType.perimeterCheck => 'perimeter_check',
    MissionType.extractionSupport => 'extraction_support',
    MissionType.eventVerification => 'event_verification',
    MissionType.customTask => 'custom_task',
  };
}
