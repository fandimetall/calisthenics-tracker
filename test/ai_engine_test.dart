import 'package:flutter_test/flutter_test.dart';
import 'package:calisthenics_tracker/services/ai/mock_ai.dart';
import 'package:calisthenics_tracker/services/ai/models/user_profile.dart';
import 'package:calisthenics_tracker/services/ai/models/workout_plan.dart';
import 'package:calisthenics_tracker/services/ai/utils/tier_determiner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mock AI Logic & Algorithms', () {
    test('Tier determination correctly classifies beginner', () {
      final profile = UserProfile(
        gender: Gender.male,
        age: 27,
        weightKg: 86.0,
        heightCm: 169.5,
        experience: WorkoutExperience.never,
        equipment: {},
      );
      final tier = TierDeterminer.determine(profile);
      expect(tier, equals('beginner'));
    });

    test('Tier determination correctly classifies intermediate', () {
      final profile = UserProfile(
        gender: Gender.male,
        age: 25,
        weightKg: 70.0,
        heightCm: 175.0,
        experience: WorkoutExperience.regular,
        equipment: {HomeEquipment.pullUpBar},
        pushupMax: 18,
        squatMax: 25,
      );
      final tier = TierDeterminer.determine(profile);
      expect(tier, equals('intermediate'));
    });

    test('Plan Generator generates correct days and nutrition', () {
      final mockLib = {
        'exercises': {
          'push': [
            {
              'id': 'push_wall',
              'name': 'Wall Push-up',
              'level': 1,
              'muscles': ['chest', 'triceps', 'shoulders'],
              'target_reps': '3x10-15',
              'equipment': 'none',
              'instructions': 'Dorong badan dari dinding dengan postur lurus.',
            }
          ],
          'pull': [
            {
              'id': 'pull_australian',
              'name': 'Australian Pull-up',
              'level': 1,
              'muscles': ['back', 'biceps'],
              'target_reps': '3x8-10',
              'equipment': 'table',
              'instructions': 'Tarik badan ke bawah meja kokoh.',
            }
          ],
          'legs': [
            {
              'id': 'squat_box',
              'name': 'Box Squat',
              'level': 1,
              'muscles': ['quads', 'glutes'],
              'target_reps': '3x10-12',
              'equipment': 'chair',
              'instructions': 'Jongkok perlahan sampai menyentuh kursi.',
            }
          ],
          'core': [
            {
              'id': 'plank_knee',
              'name': 'Knee Plank',
              'level': 1,
              'muscles': ['core', 'abs'],
              'target_reps': '3x20s',
              'equipment': 'none',
              'instructions': 'Tahan posisi plank bertumpu pada lutut.',
            }
          ]
        }
      };

      final gen = MockAiPlanGenerator(mockLib);
      final profile = UserProfile(
        gender: Gender.male,
        age: 27,
        weightKg: 86.0,
        heightCm: 169.5,
        experience: WorkoutExperience.never,
        equipment: {HomeEquipment.benchOrChair, HomeEquipment.tableOrBar},
      );

      final plan = gen.generate(profile);

      expect(plan.nutrition.bmr, greaterThan(1500));
      expect(plan.nutrition.tdeeSedentary, greaterThan(plan.nutrition.bmr));
      expect(plan.nutrition.fatLossTarget, lessThan(plan.nutrition.tdeeLight));
      expect(plan.days.isNotEmpty, isTrue);
      expect(plan.days.first.exercises.isNotEmpty, isTrue);
    });

    test('Exercise model parses warmup/cooldown without null crashes', () {
      final sampleWarmup = {
        'id': 'warmup_arm_circles',
        'name': 'Arm Circles',
        'duration': '30s',
        'instructions': 'Circle forward and backward.',
      };
      final ex = Exercise.fromJson(sampleWarmup);
      expect(ex.id, equals('warmup_arm_circles'));
      expect(ex.level, equals(1)); // default level
      expect(ex.targetReps, equals('30s')); // fallback from duration
      expect(ex.equipment, equals('none'));
    });
  });
}
