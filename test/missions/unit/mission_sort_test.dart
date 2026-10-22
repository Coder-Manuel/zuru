// Unit tests for the sort enum and the search_missions request shape.
import 'package:flutter_test/flutter_test.dart';
import 'package:zuru/modules/missions/data/models/enum.dart';
import 'package:zuru/modules/missions/data/models/mission.inputs.dart';

void main() {
  group('MissionSort', () {
    test('maps every option onto a search_missions sort', () {
      expect(MissionSort.values.map((s) => s.apiValue), [
        'distance',
        'newest',
        'pay_desc',
        'duration_asc',
      ]);
    });

    test('restores a saved name and falls back to nearest', () {
      expect(MissionSort.fromName('highestPay'), MissionSort.highestPay);
      expect(MissionSort.fromName('gone'), MissionSort.nearest);
      expect(MissionSort.fromName(null), MissionSort.nearest);
    });
  });

  group('MissionPoolEventType', () {
    test('parses known events only', () {
      expect(MissionPoolEventType.fromApi('added'), MissionPoolEventType.added);
      expect(MissionPoolEventType.fromApi('deleted'), isNull);
    });
  });

  group('SearchMissionsInput', () {
    test('a first page leaves the cursor and rate out', () {
      const input = SearchMissionsInput(lat: -1.29, lng: 36.82);

      expect(input.toMap(), {
        'p_lat': -1.29,
        'p_lng': 36.82,
        'p_sort': 'distance',
        'p_limit': 20,
      });
    });
  });
}
