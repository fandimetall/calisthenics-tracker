import '../models/user_profile.dart';

/// Tentukan tier user berdasarkan profil + simple test.
///
/// Tier: 'beginner', 'intermediate', 'advanced'
///
/// Logic berdasarkan:
/// - GymnaseTips self-test criteria
/// - Reddit BWF RR progression guide
/// - Disesuaikan untuk user tanpa pull-up bar
class TierDeterminer {
  /// Tentukan tier user.
  ///
  /// Prioritas: simple test result > experience level > BMI/age estimation
  static String determine(UserProfile profile) {
    // Kalau ada simple test data → pakai itu (paling akurat)
    if (profile.pushupMax != null && profile.squatMax != null) {
      return _fromTestResults(
        pushupMax: profile.pushupMax!,
        squatMax: profile.squatMax!,
        experience: profile.experience,
      );
    }

    // Kalau skip test → estimasi dari experience + BMI
    return _fromExperience(profile);
  }

  /// Tier dari hasil test (sumber: GymnaseTips + BWF RR)
  ///
  /// Beginner: < 5 push-ups ATAU < 10 squats
  /// Intermediate: 15+ push-ups DAN 20+ squats
  /// Advanced: 25+ push-ups DAN 40+ squats
  static String _fromTestResults({
    required int pushupMax,
    required int squatMax,
    required WorkoutExperience experience,
  }) {
    // Advanced: dominan kuat di semua
    if (pushupMax >= 25 && squatMax >= 40) {
      return 'advanced';
    }

    // Intermediate: cukup kuat
    if (pushupMax >= 15 && squatMax >= 20) {
      return 'intermediate';
    }

    // Sisanya beginner
    return 'beginner';
  }

  /// Estimasi tier dari experience saja (kalau skip test).
  static String _fromExperience(UserProfile profile) {
    switch (profile.experience) {
      case WorkoutExperience.regular:
        // Rutin workout → minimal intermediate
        // Tapi kalau BMI > 30 (obese) → tetap beginner
        if (profile.bmi > 30) return 'beginner';
        return 'intermediate';

      case WorkoutExperience.occasional:
        // Pernah tapi jarang → beginner
        return 'beginner';

      case WorkoutExperience.never:
        // Belum pernah → beginner
        return 'beginner';
    }
  }

  /// Estimasi push-up max berdasarkan profil (kalau user skip test).
  /// Dipakai untuk fine-tune exercise selection.
  static int estimatePushupMax(UserProfile profile) {
    if (profile.pushupMax != null) return profile.pushupMax!;

    int base;
    switch (profile.experience) {
      case WorkoutExperience.never:
        base = 3;
        break;
      case WorkoutExperience.occasional:
        base = 10;
        break;
      case WorkoutExperience.regular:
        base = 20;
        break;
    }

    // Adjust for BMI (overweight/obese = harder)
    if (profile.bmi > 30) base = (base * 0.6).round();
    if (profile.bmi > 25) base = (base * 0.8).round();

    // Adjust for age (older = slightly less)
    if (profile.age > 40) base = (base * 0.85).round();
    if (profile.age > 50) base = (base * 0.7).round();

    return base.clamp(1, 50);
  }

  /// Estimasi squat max.
  static int estimateSquatMax(UserProfile profile) {
    if (profile.squatMax != null) return profile.squatMax!;

    int base;
    switch (profile.experience) {
      case WorkoutExperience.never:
        base = 15;
        break;
      case WorkoutExperience.occasional:
        base = 25;
        break;
      case WorkoutExperience.regular:
        base = 40;
        break;
    }

    if (profile.bmi > 30) base = (base * 0.7).round();
    if (profile.bmi > 25) base = (base * 0.85).round();
    if (profile.age > 40) base = (base * 0.85).round();

    return base.clamp(5, 60);
  }
}
