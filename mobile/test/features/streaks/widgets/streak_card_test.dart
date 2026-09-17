import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/streaks/models/streak_models.dart';
import 'package:mobile/features/streaks/widgets/streak_card.dart';

void main() {
  testWidgets(
    'StreakCard displays current and longest streak',
    (tester) async {
      const streak = StreakResponse(
        currentStreak: 3,
        longestStreak: 7,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakCard(
              streak: streak,
            ),
          ),
        ),
      );

      expect(
        find.text('Activity Streak'),
        findsOneWidget,
      );

      expect(
        find.text('3'),
        findsOneWidget,
      );

      expect(
        find.text('7'),
        findsOneWidget,
      );

      expect(
        find.text('Current Streak'),
        findsOneWidget,
      );

      expect(
        find.text('Longest Streak'),
        findsOneWidget,
      );

      expect(
        find.byIcon(
          Icons.local_fire_department_rounded,
        ),
        findsNWidgets(2),
      );

      expect(
        find.byIcon(
          Icons.emoji_events_rounded,
        ),
        findsOneWidget,
      );
    },
  );
}