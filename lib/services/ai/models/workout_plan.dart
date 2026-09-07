/// Model untuk exercise dari library JSON.
class Exercise {
  final String id;
  final String name;
  final int level; // 1-4
  final List<String> muscles;
  final String targetReps;
  final String equipment; // "none", "pull_up_bar", dll
  final String instructions;
  final String? progressionFrom;
  final String? progressionTo;

  Exercise({
    required this.id,
    required this.name,
    required this.level,
    required this.muscles,
    required this.targetReps,
    required this.equipment,
    required this.instructions,
    this.progressionFrom,
    this.progressionTo,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Unnamed Exercise',
      level: (json['level'] as num?)?.toInt() ?? 1,
      muscles: List<String>.from(json['muscles'] ?? []),
      targetReps: json['target_reps']?.toString() ?? json['duration']?.toString() ?? '10-12',
      equipment: json['equipment'] as String? ?? 'none',
      instructions: json['instructions'] as String? ?? '',
      progressionFrom: json['progression_from'] as String?,
      progressionTo: json['progression_to'] as String?,
    );
  }

  String get categoryIcon {
    final lowerId = id.toLowerCase();
    if (lowerId.startsWith('push_') || muscles.contains('chest') || muscles.contains('triceps')) {
      return '💪'; // Push / Dada & Triceps
    } else if (lowerId.startsWith('pull_') || muscles.contains('back') || muscles.contains('biceps')) {
      return '🧗'; // Pull / Punggung & Biceps
    } else if (lowerId.startsWith('squat_') || lowerId.startsWith('lunge_') || lowerId.startsWith('calf_') || muscles.contains('quads') || muscles.contains('glutes') || muscles.contains('legs')) {
      return '🦵'; // Legs / Kaki
    } else if (lowerId.startsWith('plank_') || lowerId.startsWith('crunch_') || lowerId.startsWith('leg_raise_') || muscles.contains('core') || muscles.contains('abs')) {
      return '🎯'; // Core / Perut
    } else if (lowerId.startsWith('warmup_')) {
      return '🔥'; // Warmup / Pemanasan
    } else if (lowerId.startsWith('cooldown_')) {
      return '🧘'; // Cooldown / Pendinginan
    } else if (lowerId.startsWith('skill_') || lowerId.startsWith('handstand_') || lowerId.startsWith('lever_')) {
      return '⚡'; // Advanced Skill
    }
    return '🤸'; // Default
  }
}

/// Satu exercise dalam workout plan (dengan sets/reps/rest).
class PlannedExercise {
  final Exercise exercise;
  final int sets;
  final String reps;
  final String rest;
  final String? tips; // tips bahasa Indonesia

  PlannedExercise({
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.rest,
    this.tips,
  });
}

/// Satu hari workout.
class WorkoutDay {
  final String dayName;    // "Senin", "Rabu", "Jumat"
  final String focus;      // "Full Body", "Push", "Pull", "Legs"
  final List<PlannedExercise> exercises;
  final List<String> warmup;
  final List<String> cooldown;

  WorkoutDay({
    required this.dayName,
    required this.focus,
    required this.exercises,
    required this.warmup,
    required this.cooldown,
  });
}

/// Hasil generate: workout plan lengkap.
class WorkoutPlan {
  final String tierName;           // "Beginner", "Intermediate", "Advanced"
  final String frequency;          // "3x/minggu", "4x/minggu"
  final String durationWeeks;      // "8 minggu", "16 minggu"
  final List<WorkoutDay> days;
  final String graduationCriteria; // kapan naik level
  final NutritionEstimate nutrition;
  final List<String> notes;        // catatan khusus

  WorkoutPlan({
    required this.tierName,
    required this.frequency,
    required this.durationWeeks,
    required this.days,
    required this.graduationCriteria,
    required this.nutrition,
    required this.notes,
  });
}

/// Estimasi nutrisi sederhana.
class NutritionEstimate {
  final double bmr;
  final double tdeeSedentary;
  final double tdeeLight;
  final double fatLossTarget;    // TDEE - 500
  final double proteinMinG;     // weight * 1.6
  final double proteinMaxG;     // weight * 2.0
  final String bmiCategory;
  final double bmi;

  NutritionEstimate({
    required this.bmr,
    required this.tdeeSedentary,
    required this.tdeeLight,
    required this.fatLossTarget,
    required this.proteinMinG,
    required this.proteinMaxG,
    required this.bmiCategory,
    required this.bmi,
  });
}
