import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/activities/models/activity_models.dart';

void main() {
  test(
    'ActivityTrendResponse should parse trend response',
    () {
      final json = {
        'from': '2026-09-01T00:00:00Z',
        'to': '2026-09-11T00:00:00Z',
        'type': null,
        'groupBy': 'day',
        'items': [
          {
            'date': '2026-09-01T00:00:00Z',
            'totalActivities': 2,
            'totalDistance': 10.5,
            'totalDurationSeconds': 3600,
            'totalCalories': 650.0,
          },
          {
            'date': '2026-09-02T00:00:00Z',
            'totalActivities': 1,
            'totalDistance': 5.2,
            'totalDurationSeconds': 1800,
            'totalCalories': 340.0,
          },
        ],
      };

      final response =
          ActivityTrendResponse.fromJson(json);

      expect(response.from, isNotNull);
      expect(response.to, isNotNull);
      expect(response.type, isNull);
      expect(response.groupBy, 'day');

      expect(response.items, hasLength(2));

      expect(
        response.items[0].totalActivities,
        2,
      );

      expect(
        response.items[0].totalDistance,
        10.5,
      );

      expect(
        response.items[0].totalDurationSeconds,
        3600,
      );

      expect(
        response.items[0].totalCalories,
        650.0,
      );

      expect(
        response.items[1].totalDistance,
        5.2,
      );
    },
  );

  test(
    'ActivityTrendResponse should parse empty items',
    () {
      final json = {
        'from': null,
        'to': null,
        'type': null,
        'groupBy': 'day',
        'items': [],
      };

      final response =
          ActivityTrendResponse.fromJson(json);

      expect(response.items, isEmpty);
      expect(response.groupBy, 'day');
    },
  );
}