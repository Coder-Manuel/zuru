enum UserRole { client, scout }

enum UserStatus { active, inactive, suspended }

/// Scout-only booking availability shown on the World Profile.
///
/// Distinct from [UserStatus] (which gates the account itself) — this controls
/// whether clients can see and book the scout right now.
enum ScoutAvailability { available, bookable, offline }

extension ScoutAvailabilityX on ScoutAvailability {
  String get label => switch (this) {
    ScoutAvailability.available => 'Available',
    ScoutAvailability.bookable => 'Bookable',
    ScoutAvailability.offline => 'Offline',
  };
}
