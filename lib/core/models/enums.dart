enum UserRole { client, scout }

enum UserStatus { active, inactive, suspended }

/// Scout-only booking availability shown on the World Profile.
///
/// Distinct from [UserStatus] (which gates the account itself) — this controls
/// whether clients can see and book the scout right now.
enum ScoutAvailability { available, bookable, offline }

/// The three fixed slots a scout can fill with a [ProfileClip].
enum ClipType { world, speciality, personal }

extension ScoutAvailabilityX on ScoutAvailability {
  String get label => switch (this) {
    ScoutAvailability.available => 'Available',
    ScoutAvailability.bookable => 'Bookable',
    ScoutAvailability.offline => 'Offline',
  };
}

extension ClipTypeX on ClipType {
  String get label => switch (this) {
    ClipType.world => 'World Clip',
    ClipType.speciality => 'Speciality',
    ClipType.personal => 'Personal',
  };
}
