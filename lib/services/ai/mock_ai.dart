import 'dart:convert';
import 'models/user_profile.dart';
import 'models/workout_plan.dart';
import 'utils/equipment_filter.dart';
import 'utils/tier_determiner.dart';

/// Mock AI Plan Generator.
///
/// Terima UserProfile → hasilkan WorkoutPlan lengkap.
/// Tidak pakai API/model AI — murni rules + template dari exercise library.
///
/// Sumber data:
/// - Reddit BWF Recommended Routine
/// - GymnaseTips Calisthenics Chart (50+ moves)
/// - Odin Fitness Progressive Overload Science
/// - Schoenfeld 2010/2017 (mechanical tension, dose-response)
class MockAiPlanGenerator {
  final Map<String, dynamic> _library;

  MockAiPlanGenerator(this._library);

  /// Load dari JSON string.
  factory MockAiPlanGenerator.fromJsonString(String jsonString) {
    return MockAiPlanGenerator(json.decode(jsonString));
  }

  // ─── PUBLIC API ───────────────────────────────────────────

  /// Generate workout plan lengkap dari user profile.
  WorkoutPlan generate(UserProfile profile) {
    final tier = TierDeterminer.determine(profile);
    final available = _filterExercises(profile.equipment);
    final nutrition = _calcNutrition(profile);

    switch (tier) {
      case 'intermediate':
        return _buildIntermediate(profile, available, nutrition);
      case 'advanced':
        return _buildAdvanced(profile, available, nutrition);
      default:
        return _buildBeginner(profile, available, nutrition);
    }
  }

  // ─── EXERCISE FILTERING ───────────────────────────────────

  /// Filter semua exercise berdasarkan equipment user.
  Map<String, List<Exercise>> _filterExercises(Set<HomeEquipment> userEquip) {
    final result = <String, List<Exercise>>{};
    final exercises = _library['exercises'] as Map<String, dynamic>;

    for (final cat in exercises.keys) {
      final list = exercises[cat] as List;
      final filtered = <Exercise>[];

      for (final ex in list) {
        final exercise = Exercise.fromJson(ex as Map<String, dynamic>);
        final equip = exercise.equipment;

        if (EquipmentFilter.userCanDo(equip, userEquip)) {
          filtered.add(exercise);
        }
      }
      result[cat] = filtered;
    }
    return result;
  }

  /// Ambil exercise terbaik untuk level tertentu.
  /// Kalau level yang diminta kosong, turunkan 1 level.
  List<Exercise> _pickForLevel(
    List<Exercise> pool,
    int targetLevel, {
    int count = 2,
  }) {
    // Coba level yang diminta
    var picks = pool.where((e) => e.level == targetLevel).toList();
    if (picks.isNotEmpty) {
      return picks.take(count).toList();
    }

    // Fallback: level di bawahnya
    for (var lvl = targetLevel - 1; lvl >= 1; lvl--) {
      picks = pool.where((e) => e.level == lvl).toList();
      if (picks.isNotEmpty) return picks.take(count).toList();
    }

    return [];
  }

  /// Ambil warmup exercises.
  List<String> _getWarmup() {
    final warmup = _library['exercises']['warmup'] as List? ?? [];
    return warmup.map<String>((e) {
      final name = e['name'] as String;
      final dur = e['duration'] as String? ?? '';
      return '$name — $dur';
    }).toList();
  }

  /// Ambil cooldown exercises.
  List<String> _getCooldown() {
    final cooldown = _library['exercises']['cooldown'] as List? ?? [];
    return cooldown.map<String>((e) {
      final name = e['name'] as String;
      final dur = e['duration'] as String? ?? '';
      return '$name — $dur';
    }).toList();
  }

  // ─── BEGINNER PLAN ────────────────────────────────────────

  WorkoutPlan _buildBeginner(
    UserProfile profile,
    Map<String, List<Exercise>> available,
    NutritionEstimate nutrition,
  ) {
    final pushPool = available['push'] ?? [];
    final legsPool = available['legs'] ?? [];
    final corePool = available['core'] ?? [];
    final pullPool = available['pull'] ?? [];
    final warmup = _getWarmup();
    final cooldown = _getCooldown();

    // Beginner: 3 reps/set range, 3 sets
    final pushL1 = _pickForLevel(pushPool, 1, count: 3);
    final legsL1 = _pickForLevel(legsPool, 1, count: 3);
    final coreL1 = _pickForLevel(corePool, 1, count: 3);
    final pullL1 = _pickForLevel(pullPool, 1, count: 2);

    // Beginner level 2 (untuk variasi hari berbeda)
    final pushL2 = _pickForLevel(pushPool, 2, count: 2);
    final legsL2 = _pickForLevel(legsPool, 2, count: 2);
    final coreL2 = _pickForLevel(corePool, 2, count: 2);

    // Helper: buat PlannedExercise dari Exercise
    PlannedExercise plan(Exercise ex, {int sets = 3, String? reps, String rest = '60s'}) {
      return PlannedExercise(
        exercise: ex,
        sets: sets,
        reps: reps ?? _beginnerReps(ex),
        rest: rest,
        tips: _tipForExercise(ex),
      );
    }

    // DAY A: Push L1 + Legs L1 + Core L1
    final dayA = WorkoutDay(
      dayName: 'Senin',
      focus: 'Full Body A',
      warmup: warmup,
      cooldown: cooldown,
      exercises: [
        if (pushL1.isNotEmpty) plan(pushL1[0]),
        if (legsL1.isNotEmpty) plan(legsL1[0]),
        if (legsL1.length > 1) plan(legsL1[1]),
        if (pullL1.isNotEmpty) plan(pullL1[0]),
        if (coreL1.isNotEmpty) plan(coreL1[0], rest: '45s'),
        if (coreL1.length > 1) plan(coreL1[1], rest: '45s'),
      ],
    );

    // DAY B: Push variasi + Legs variasi + Core variasi
    final dayB = WorkoutDay(
      dayName: 'Rabu',
      focus: 'Full Body B',
      warmup: warmup,
      cooldown: cooldown,
      exercises: [
        if (pushL1.length > 1) plan(pushL1[1])
        else if (pushL2.isNotEmpty) plan(pushL2[0]),
        if (legsL2.isNotEmpty) plan(legsL2[0]),
        if (legsL1.length > 2) plan(legsL1[2])
        else if (legsL2.length > 1) plan(legsL2[1]),
        if (pullL1.length > 1) plan(pullL1[1]),
        if (coreL2.isNotEmpty) plan(coreL2[0], rest: '45s'),
        if (coreL1.length > 2) plan(coreL1[2], rest: '45s'),
      ],
    );

    // DAY C: Mix terbaik A+B
    final dayC = WorkoutDay(
      dayName: 'Jumat',
      focus: 'Full Body C',
      warmup: warmup,
      cooldown: cooldown,
      exercises: [
        if (pushL2.isNotEmpty) plan(pushL2[0])
        else if (pushL1.isNotEmpty) plan(pushL1[0]),
        if (legsL1.isNotEmpty) plan(legsL1[0]),
        if (legsL2.isNotEmpty) plan(legsL2[0]),
        if (pullPool.isNotEmpty) plan(pullPool.first),
        if (coreL1.isNotEmpty) plan(coreL1[0], rest: '45s'),
        if (coreL2.length > 1) plan(coreL2[1], rest: '45s'),
      ],
    );

    // Notes khusus
    final notes = <String>[];

    if (pullPool.isEmpty) {
      notes.add(
        '⚠️ TANPA PULL-UP BAR — gerakan punggung terbatas. '
        'Alternatif tanpa alat: Superman Hold (terlentang, angkat tangan+kaki 3x10), '
        'Doorway Row (pegang kusen pintu, tarik badan 3x8-12). '
        'Sangat disarankan beli pull-up bar door-mount (Rp 80-150rb).',
      );
    }

    if (nutrition.bmi >= 25) {
      notes.add(
        '🔥 BMI ${nutrition.bmi.toStringAsFixed(1)} (${nutrition.bmiCategory}) — '
        'kombinasi workout + deficit kalori 500 kcal/hari akan bantu turunkan BB '
        '~0.5 kg/minggu secara sehat.',
      );
    }

    notes.add(
      '📈 PROGRESSION: Kalau sudah bisa 3x12 dengan form bagus → '
      'naikkan ke variasi lebih sulit. Contoh: wall push-up → incline → knee → full.',
    );

    notes.add(
      '🏃 REST DAY: Istirahat total atau jalan kaki 20-30 menit. '
      'Jangan workout 2 hari berturut-turut di minggu pertama.',
    );

    if (profile.runPaceMinPerKm != null && profile.runPaceMinPerKm! > 8) {
      notes.add(
        '🏃 CARDIO: Pace ${profile.runPaceMinPerKm} min/km — '
        'tambahkan jalan cepat/jogging 20 menit di rest day. '
        'Target: turunkan ke 8 min/km dalam 8 minggu.',
      );
    }

    return WorkoutPlan(
      tierName: 'Beginner',
      frequency: '3x/minggu (Senin, Rabu, Jumat)',
      durationWeeks: '8 minggu',
      days: [dayA, dayB, dayC],
      graduationCriteria: '15 push-ups, 5 pull-ups (kalau punya bar), 20 squats — semua strict form',
      nutrition: nutrition,
      notes: notes,
    );
  }

  // ─── INTERMEDIATE PLAN ────────────────────────────────────

  WorkoutPlan _buildIntermediate(
    UserProfile profile,
    Map<String, List<Exercise>> available,
    NutritionEstimate nutrition,
  ) {
    final pushPool = available['push'] ?? [];
    final pullPool = available['pull'] ?? [];
    final legsPool = available['legs'] ?? [];
    final corePool = available['core'] ?? [];
    final warmup = _getWarmup();
    final cooldown = _getCooldown();

    final pushL2 = _pickForLevel(pushPool, 2, count: 3);
    final pushL3 = _pickForLevel(pushPool, 3, count: 2);
    final pullL3 = _pickForLevel(pullPool, 3, count: 3);
    final legsL2 = _pickForLevel(legsPool, 2, count: 3);
    final legsL3 = _pickForLevel(legsPool, 3, count: 2);
    final coreL2 = _pickForLevel(corePool, 2, count: 3);
    final coreL3 = _pickForLevel(corePool, 3, count: 2);

    PlannedExercise plan(Exercise ex, {int sets = 4, String? reps, String rest = '60s'}) {
      return PlannedExercise(
        exercise: ex,
        sets: sets,
        reps: reps ?? ex.targetReps,
        rest: rest,
        tips: _tipForExercise(ex),
      );
    }

    // Push day
    final pushDay = WorkoutDay(
      dayName: 'Senin',
      focus: 'Push (Dada, Bahu, Triceps)',
      warmup: warmup,
      cooldown: cooldown,
      exercises: [
        ...pushL2.map((e) => plan(e, sets: 4)),
        ...pushL3.map((e) => plan(e, sets: 3)),
        if (coreL2.isNotEmpty) plan(coreL2[0], sets: 3, rest: '45s'),
      ],
    );

    // Pull day
    final pullDay = WorkoutDay(
      dayName: 'Selasa',
      focus: 'Pull (Punggung, Biceps)',
      warmup: warmup,
      cooldown: cooldown,
      exercises: [
        ...pullL3.map((e) => plan(e, sets: 4, rest: '90s')),
        if (coreL3.isNotEmpty) plan(coreL3[0], sets: 3, rest: '45s'),
        if (coreL2.length > 1) plan(coreL2[1], sets: 3, rest: '45s'),
      ],
    );

    // Legs day
    final legsDay = WorkoutDay(
      dayName: 'Kamis',
      focus: 'Legs (Kaki, Glute)',
      warmup: warmup,
      cooldown: cooldown,
      exercises: [
        ...legsL2.map((e) => plan(e, sets: 4)),
        ...legsL3.map((e) => plan(e, sets: 3, rest: '90s')),
        if (coreL2.length > 2) plan(coreL2[2], sets: 3, rest: '45s'),
      ],
    );

    // Upper day (mix push+pull)
    final upperDay = WorkoutDay(
      dayName: 'Jumat',
      focus: 'Upper Body (Gabungan)',
      warmup: warmup,
      cooldown: cooldown,
      exercises: [
        if (pushL2.isNotEmpty) plan(pushL2[0], sets: 3),
        if (pullL3.isNotEmpty) plan(pullL3[0], sets: 3, rest: '90s'),
        if (pushL3.isNotEmpty) plan(pushL3[0], sets: 3),
        if (pullL3.length > 1) plan(pullL3[1], sets: 3, rest: '90s'),
        if (coreL3.isNotEmpty) plan(coreL3[0], sets: 3, rest: '45s'),
      ],
    );

    final notes = <String>[];
    if (pullPool.isEmpty) {
      notes.add(
        '⚠️ TANPA PULL-UP BAR — Pull day tidak optimal. '
        'Beli pull-up bar (Rp 80-150rb) agar bisa melatih punggung dengan benar.',
      );
    }
    notes.add(
      '📈 TARGET: 10-15 hard sets per muscle group per minggu. '
      'Setiap set → 1-2 rep sebelum gagal (RIR 1-2).',
    );

    return WorkoutPlan(
      tierName: 'Intermediate',
      frequency: '4x/minggu (Senin, Selasa, Kamis, Jumat)',
      durationWeeks: '16 minggu',
      days: [pushDay, pullDay, legsDay, upperDay],
      graduationCriteria: '25 push-ups, 10 pull-ups, pistol squat negatives solid',
      nutrition: nutrition,
      notes: notes,
    );
  }

  // ─── ADVANCED PLAN ────────────────────────────────────────

  WorkoutPlan _buildAdvanced(
    UserProfile profile,
    Map<String, List<Exercise>> available,
    NutritionEstimate nutrition,
  ) {
    final pushPool = available['push'] ?? [];
    final pullPool = available['pull'] ?? [];
    final legsPool = available['legs'] ?? [];
    final corePool = available['core'] ?? [];
    final skillPool = available['skill'] ?? [];
    final warmup = _getWarmup();
    final cooldown = _getCooldown();

    final pushL3 = _pickForLevel(pushPool, 3, count: 3);
    final pushL4 = _pickForLevel(pushPool, 4, count: 2);
    final pullL3 = _pickForLevel(pullPool, 3, count: 2);
    final pullL4 = _pickForLevel(pullPool, 4, count: 3);
    final legsL3 = _pickForLevel(legsPool, 3, count: 3);
    final legsL4 = _pickForLevel(legsPool, 4, count: 2);
    final coreL3 = _pickForLevel(corePool, 3, count: 2);
    final coreL4 = _pickForLevel(corePool, 4, count: 2);
    final skillL3 = _pickForLevel(skillPool, 3, count: 2);
    final skillL4 = _pickForLevel(skillPool, 4, count: 2);

    PlannedExercise plan(Exercise ex, {int sets = 4, String? reps, String rest = '90s'}) {
      return PlannedExercise(
        exercise: ex,
        sets: sets,
        reps: reps ?? ex.targetReps,
        rest: rest,
        tips: _tipForExercise(ex),
      );
    }

    // Day 1: Horizontal Push + Pull
    final day1 = WorkoutDay(
      dayName: 'Senin',
      focus: 'Horizontal Push & Pull',
      warmup: warmup,
      cooldown: cooldown,
      exercises: [
        ...pushL3.map((e) => plan(e, sets: 4)),
        ...pullL3.map((e) => plan(e, sets: 4)),
        if (coreL3.isNotEmpty) plan(coreL3[0], sets: 3, rest: '60s'),
      ],
    );

    // Day 2: Vertical Push + Pull (skill focus)
    final day2 = WorkoutDay(
      dayName: 'Selasa',
      focus: 'Vertical Push & Pull + Skills',
      warmup: warmup,
      cooldown: cooldown,
      exercises: [
        ...pushL4.map((e) => plan(e, sets: 5, reps: '3-5')),
        ...pullL4.map((e) => plan(e, sets: 4)),
        ...skillL3.map((e) => plan(e, sets: 4, reps: '5-15s hold')),
      ],
    );

    // Day 3: Legs + Core
    final day3 = WorkoutDay(
      dayName: 'Kamis',
      focus: 'Legs & Core',
      warmup: warmup,
      cooldown: cooldown,
      exercises: [
        ...legsL3.map((e) => plan(e, sets: 4)),
        ...legsL4.map((e) => plan(e, sets: 3)),
        ...coreL4.map((e) => plan(e, sets: 3, rest: '60s')),
      ],
    );

    // Day 4: Skills
    final day4 = WorkoutDay(
      dayName: 'Jumat',
      focus: 'Skill Practice',
      warmup: warmup,
      cooldown: cooldown,
      exercises: [
        ...skillL4.map((e) => plan(e, sets: 5, reps: '3-10s hold', rest: '120s')),
        ...skillL3.map((e) => plan(e, sets: 4, reps: '10-20s hold')),
        if (coreL3.length > 1) plan(coreL3[1], sets: 3, rest: '60s'),
      ],
    );

    // Day 5: Conditioning
    final day5 = WorkoutDay(
      dayName: 'Sabtu',
      focus: 'Conditioning & Volume',
      warmup: warmup,
      cooldown: cooldown,
      exercises: [
        if (pushL3.isNotEmpty) plan(pushL3[0], sets: 3, reps: '12-15'),
        if (pullL3.isNotEmpty) plan(pullL3[0], sets: 3, reps: '10-12'),
        if (legsL3.isNotEmpty) plan(legsL3[0], sets: 3, reps: '12-15'),
        if (coreL3.isNotEmpty) plan(coreL3[0], sets: 3, rest: '60s'),
      ],
    );

    return WorkoutPlan(
      tierName: 'Advanced',
      frequency: '5x/minggu (Senin–Jumat atau Senin–Sabtu)',
      durationWeeks: '12 minggu (3 phase: accumulation → intensification → realization)',
      days: [day1, day2, day3, day4, day5],
      graduationCriteria: 'Muscle-up, front lever hold 10s, one-arm pull-up, pistol squat 10 reps',
      nutrition: nutrition,
      notes: [
        '🎯 12-WEEK BLOCK: Phase 1 (wk1-4) volume, Phase 2 (wk5-8) intensity, Phase 3 (wk9-12) test skill.',
        '⏸️ DELOAD di Week 8: potong sets jadi setengah, skill practice tetap ringan.',
        '🦴 Advanced = tendon-limited, bukan muscle-limited. Jaga sendi (siku, bahu, pergelangan).',
      ],
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────

  /// Reps untuk beginner berdasarkan tipe exercise.
  String _beginnerReps(Exercise ex) {
    if (ex.targetReps.contains('s')) {
      // Timed hold → kurangi untuk beginner
      return '15-20s';
    }
    // Rep-based → mulai rendah
    final target = ex.targetReps;
    if (target.contains('per')) return '8 ${target.split(' ').last}'; // "8 per side"
    return '8-12';
  }

  /// Tips bahasa Indonesia untuk exercise.
  String? _tipForExercise(Exercise ex) {
    final tips = <String, String>{
      'push_wall': 'Tangan di tembok setinggi dada, badan lurus, dorong sampai lengan lurus',
      'push_knee': 'Lutut di lantai, turunkan dada pelan sampai hampir sentuh lantai',
      'push_incline': 'Tangan di kursi/meja, badan lurus dari kepala ke kaki',
      'push_standard': 'Badan lurus, turunkan dada ke lantai, dorong naik dengan kuat',
      'push_diamond': 'Tangan bentuk diamond di bawah dada, siku rapat badan',
      'push_wide': 'Tangan lebih lebar dari bahu, fokus regangan dada',
      'push_pike': 'Pinggul naik tinggi membentuk V, turunkan kepala ke lantai',
      'push_archer': 'Satu tangan lurus ke samping, beban di tangan satunya',
      'push_onearm': 'Kaki lebar, satu tangan di belakang, dorong dengan satu tangan',
      'push_clap': 'Dorong kuat sampai tangan lepas lantai, tepuk, mendarat lembut',
      'legs_bw_squat': 'Kaki selebar bahu, turun sampai paha sejajar lantai, punggung lurus',
      'legs_glute_bridge': 'Terlentang, lutut ditekuk, angkat pinggul tinggi, squeeze glute',
      'legs_wall_sit': 'Punggung rata di tembok, paha sejajar lantai, tahan',
      'legs_reverse_lunge': 'Langkah ke belakang, lutut hampir sentuh lantai, dorong naik',
      'legs_walking_lunge': 'Langkah panjang ke depan, lutut belakang hampir sentuh lantai',
      'legs_calf_raise': 'Berdiri, angkat tumit setinggi mungkin, tahan 1 detik, turunkan pelan',
      'legs_jump_squat': 'Squat biasa, lompat kuat, mendarat lembut dengan lutut ditekuk',
      'legs_pistol_neg': 'Berdiri satu kaki, turun pelan ke kursi, kontrol 3-5 detik',
      'legs_pistol_full': 'Berdiri satu kaki, turun penuh, naik tanpa bantuan',
      'core_plank_knee': 'Siku di lantai, lutut juga, badan lurus dari kepala ke lutut',
      'core_plank': 'Siku dan ujung kaki di lantai, badan lurus, kencangkan perut',
      'core_dead_bug': 'Terlentang, tangan+kaki ke atas, gerak berlawanan pelan-pelan',
      'core_crunch': 'Terlentang, angkat bahu dari lantai, jangan tarik leher',
      'core_bicycle_crunch': 'Terlentang, siku ke lutut berlawanan bergantian',
      'core_side_plank': 'Miring, siku di lantai, angkat pinggul, badan lurus',
      'core_hollow_hold': 'Terlentang, angkat bahu+kaki dari lantai, punggung bawah rata lantai',
      'core_leg_raise_lying': 'Terlentang, angkat kaki lurus ke 90°, turunkan pelan',
    };
    return tips[ex.id];
  }

  /// Hitung estimasi nutrisi.
  NutritionEstimate _calcNutrition(UserProfile profile) {
    return NutritionEstimate(
      bmr: profile.bmr,
      tdeeSedentary: profile.tdeeSedentary(),
      tdeeLight: profile.tdeeLight(),
      fatLossTarget: profile.tdeeSedentary() - 500,
      proteinMinG: profile.weightKg * 1.6,
      proteinMaxG: profile.weightKg * 2.0,
      bmiCategory: profile.bmiCategory,
      bmi: profile.bmi,
    );
  }
}
