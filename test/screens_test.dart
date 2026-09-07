import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calisthenics_tracker/features/workout/workout_session_screen.dart';
import 'package:calisthenics_tracker/features/library/exercise_library_screen.dart';

void main() {
  testWidgets('WorkoutSessionScreen renders timer and controls cleanly', (WidgetTester tester) async {
    final mockDay = {
      'day': 1,
      'focus': 'Full Body Foundation',
      'exercises': [
        {
          'id': 'push_wall',
          'name': 'Wall Push-up',
          'sets': 3,
          'reps': '15-20',
          'rest_seconds': 60,
        }
      ]
    };

    await tester.pumpWidget(
      MaterialApp(
        home: WorkoutSessionScreen(
          workoutDay: mockDay,
        ),
      ),
    );

    expect(find.text('Wall Push-up'), findsOneWidget);
    expect(find.text('Full Body Foundation'), findsOneWidget);
    expect(find.text('Selesai Latihan'), findsOneWidget);
  });

  testWidgets('ExerciseLibraryScreen builds search field and category chips', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ExerciseLibraryScreen(),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
  });
}
