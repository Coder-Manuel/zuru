import 'package:flutter_test/flutter_test.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/modules/missions/data/models/nearby_scout.model.dart';

void main() {
  // One row exactly as get_nearby_scouts returns it.
  final row = <String, dynamic>{
    'id': 'd7d7d240-ee62-44d3-b023-667ad82f526b',
    'first_name': 'Smith',
    'last_name': 'Rowe',
    'phone': '254712345678',
    'rating': 1.0,
    'total_reviews': 3,
    'tags': 'Security,Surveillance,Real Estate,Sports,Environmental',
    'avatar_url': 'https://example.supabase.co/storage/v1/object/public/a.jpg',
    'is_online': true,
    'fcm_token': 'cEYnT4rlQg29WVm1jFOXHH:APA91bEbmhuAAgg',
    'created_at': '2026-06-01T14:01:28.969535+00:00',
    'updated_at': '2026-07-25T11:05:54.425715+00:00',
    'distance_meters': 3404.74252258,
  };

  test('flat RPC row normalises into User + scout Profile', () {
    final scout = NearbyScoutModel.fromMap(row);
    final profile = scout.user.scoutProfile;

    expect(profile, isNotNull, reason: 'UI reads user.scoutProfile');
    expect(profile!.displayName, 'Smith R.');
    expect(profile.fullName, 'Smith Rowe');
    expect(profile.rating, 1.0);
    expect(profile.totalReviews, 3);
    expect(profile.avatarUrl, isNotNull);
    expect(profile.id, 'd7d7d240-ee62-44d3-b023-667ad82f526b');
    expect(profile.role, UserRole.scout);
    expect(profile.tags, [
      'Security', 'Surveillance', 'Real Estate', 'Sports', 'Environmental',
    ]);

    expect(scout.user.isOnline, isTrue);
    expect(scout.user.phone, '254712345678');
    expect(scout.user.fcmToken, startsWith('cEYnT4r'));
    expect(scout.user.status, UserStatus.active);
    expect(scout.distanceMeters, closeTo(3404.74, 0.01));
  });

  test('tags also survive as a real Postgres text[] (List)', () {
    final scout = NearbyScoutModel.fromMap({
      ...row,
      'tags': ['Security', 'Real Estate'],
    });
    expect(scout.user.scoutProfile!.tags, ['Security', 'Real Estate']);
  });

  test('nulls and a missing user_id do not throw', () {
    final scout = NearbyScoutModel.fromMap({
      ...row,
      'avatar_url': null,
      'tags': null,
      'rating': null,
      'distance_meters': null,
    });
    expect(scout.user.id, isNull);
    expect(scout.user.scoutProfile!.tags, isEmpty);
    expect(scout.distanceMeters, 0);
  });
}
