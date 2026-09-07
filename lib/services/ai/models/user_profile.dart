/// Equipment yang mungkin dimiliki user di rumah.
/// Mapping ke equipment string di exercise_library.json.
enum HomeEquipment {
  pullUpBar,       // pull_up_bar, pull_up_bar_or_rings
  resistanceBand,  // resistance_band
  benchOrChair,    // bench_or_chair, bench_or_step, bench_or_box, bench
  tableOrBar,      // bar_at_waist_height_or_table, low_bar_or_table_edge
  parallettes,     // parallettes_or_floor, parallettes_optional
  none,            // user punya NOTHING
}

/// Experience level user.
enum WorkoutExperience {
  never,       // belum pernah workout sama sekali
  occasional,  // pernah tapi jarang / on-off
  regular,     // rutin workout (3+ bulan terakhir)
}

/// Gender user.
enum Gender { male, female }

/// Profil user dari onboarding.
class UserProfile {
  final Gender gender;
  final int age;
  final double weightKg;
  final double heightCm;
  final WorkoutExperience experience;
  final Set<HomeEquipment> equipment;

  // Simple test (opsional, bisa null kalau skip)
  final int? pushupMax;
  final int? squatMax;
  final double? runPaceMinPerKm;

  UserProfile({
    required this.gender,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.experience,
    required this.equipment,
    this.pushupMax,
    this.squatMax,
    this.runPaceMinPerKm,
  });

  /// BMI = weight / (height in meters)^2
  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  /// BMI category string
  String get bmiCategory {
    if (bmi < 18.5) return 'underweight';
    if (bmi < 25) return 'normal';
    if (bmi < 30) return 'overweight';
    return 'obese';
  }

  /// BMR (Mifflin-St Jeor)
  double get bmr {
    if (gender == Gender.male) {
      return 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    }
    return 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
  }

  /// TDEE berdasarkan activity level
  double tdeeSedentary() => bmr * 1.2;
  double tdeeLight() => bmr * 1.375;
  double tdeeModerate() => bmr * 1.55;

  /// Apakah user punya equipment tertentu
  bool hasEquipment(HomeEquipment eq) => equipment.contains(eq);

  /// Apakah user punya MINIMAL 1 alat (selain none)
  bool get hasAnyEquipment =>
      equipment.isNotEmpty &&
      !(equipment.length == 1 && equipment.contains(HomeEquipment.none));
}
