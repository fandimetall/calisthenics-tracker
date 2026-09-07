import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/ai/models/user_profile.dart';
import '../../services/ai/mock_ai.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../core/widgets/responsive_layout.dart';
import '../../services/supabase_service.dart';

/// Onboarding 7 langkah (match design mockup):
/// Q1 gender, Q2 umur, Q3 BB, Q4 TB, Q5 experience, Q6 alat, Q7 test opsional
/// → Mock AI generate plan → selesai.
class OnboardingScreen extends StatefulWidget {
  final String userEmail;
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.userEmail, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _auth = AuthService();
  final _lib = <String, dynamic>{};

  int _step = 0; // 0..6
  // answers
  Gender _gender = Gender.male;
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  WorkoutExperience _experience = WorkoutExperience.never;
  final Set<HomeEquipment> _equipment = {};
  final _pushup = TextEditingController();
  final _squat = TextEditingController();
  final _pace = TextEditingController();
  bool _skipTest = false;
  Map<String, dynamic>? _generatedPlan;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  @override
  void dispose() {
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    _pushup.dispose();
    _squat.dispose();
    _pace.dispose();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    String raw = '';
    try {
      raw = await rootBundle.loadString('assets/data/exercise_library.json');
    } catch (_) {
      raw = await rootBundle.loadString('assets/assets/data/exercise_library.json');
    }
    if (!mounted) return;
    setState(() => _lib.addAll(json.decode(raw) as Map<String, dynamic>));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: ResponsiveContentContainer(
          maxWidth: 540,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: List.generate(7, (i) => Expanded(
                    child: Container(
                      height: 4, margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _step ? AppColors.accent : (isDark ? AppColors.surface2Dark : AppColors.surface2Light),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                ),
              ),
              Expanded(child: _body(isDark)),
              if (_step < 7)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: FilledButton(
                    onPressed: _canNext ? _next : null,
                    child: Text(_step == 6 ? (_generating ? 'Menyusun plan…' : 'Generate Plan AI 🤖') : 'Lanjut →'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(bool isDark) {
    switch (_step) {
      case 0: return _qGender(isDark);
      case 1: return _qNumber(isDark, 'Berapa umur kamu?', _age, 'tahun');
      case 2: return _qNumber(isDark, 'Berat badan kamu?', _weight, 'kg');
      case 3: return _qNumber(isDark, 'Tinggi badan kamu?', _height, 'cm');
      case 4: return _qExperience(isDark);
      case 5: return _qEquipment(isDark);
      case 6: return _qTest(isDark);
      default: return _result(isDark);
    }
  }

  Widget _qTitle(bool isDark, String title, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, height: 1.25)),
        const SizedBox(height: 8),
        Text(hint, style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight)),
      ]),
    );
  }

  Widget _qGender(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _qTitle(isDark, 'Jenis kelamin kamu?', 'Dipakai untuk hitung kalori & BMR.'),
      const SizedBox(height: 24),
      _opt(isDark, 'Pria 👨', _gender == Gender.male, () => setState(() => _gender = Gender.male)),
      _opt(isDark, 'Wanita 👩', _gender == Gender.female, () => setState(() => _gender = Gender.female)),
    ]);
  }

  Widget _qNumber(bool isDark, String title, TextEditingController c, String unit) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _qTitle(isDark, title, 'Ketik angka di bawah.'),
      const SizedBox(height: 24),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}), // rebuild agar _canNext terupdate
          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800),
          decoration: InputDecoration(hintText: '0', suffixText: unit, suffixStyle: GoogleFonts.inter(fontSize: 14, color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight)),
        ),
      ),
    ]);
  }

  Widget _qExperience(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _qTitle(isDark, 'Pengalaman workout kamu?', 'Jujur saja — ini menentukan level gerakannya.'),
      const SizedBox(height: 24),
      _opt(isDark, 'Belum pernah sama sekali', _experience == WorkoutExperience.never, () => setState(() => _experience = WorkoutExperience.never)),
      _opt(isDark, 'Pernah tapi jarang', _experience == WorkoutExperience.occasional, () => setState(() => _experience = WorkoutExperience.occasional)),
      _opt(isDark, 'Rutin (3+ bulan)', _experience == WorkoutExperience.regular, () => setState(() => _experience = WorkoutExperience.regular)),
    ]);
  }

  Widget _qEquipment(bool isDark) {
    Widget eq(String label, String icon, HomeEquipment e) {
      final sel = _equipment.contains(e);
      final bgColor = sel
          ? (isDark ? AppColors.accentSoftDark : AppColors.accentSoftLight)
          : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
      final textColor = isDark ? AppColors.inkDark : AppColors.inkLight;
      final borderColor = sel
          ? (isDark ? AppColors.accentDark : AppColors.accent)
          : (isDark ? AppColors.borderDark : AppColors.borderLight);

      return GestureDetector(
        onTap: () => setState(() => sel ? _equipment.remove(e) : _equipment.add(e)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textColor), textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _qTitle(isDark, 'Alat apa saja yang kamu punya?', 'Pilih semua yang ada. Nggak punya apapun? Skip aja.'),
      const SizedBox(height: 20),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.count(
            crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.4,
            children: [
              eq('Pull-up bar', '🪜', HomeEquipment.pullUpBar),
              eq('Resistance band', '🎗️', HomeEquipment.resistanceBand),
              eq('Kursi / bangku', '🪑', HomeEquipment.benchOrChair),
              eq('Meja kokoh', '🛋️', HomeEquipment.tableOrBar),
              eq('Parallettes', '🤸', HomeEquipment.parallettes),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _qTest(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _qTitle(isDark, 'Simple Test (opsional)', 'Biar plan makin akurat. Skip juga boleh.'),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          CheckboxListTile(
            value: _skipTest,
            onChanged: (v) => setState(() => _skipTest = v ?? false),
            title: Text('Skip test — pakai estimasi saja', style: GoogleFonts.inter(fontSize: 14)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          if (!_skipTest) ...[
            TextField(controller: _pushup, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Push-up max (kali)')),
            const SizedBox(height: 12),
            TextField(controller: _squat, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Squat max (kali)')),
            const SizedBox(height: 12),
            TextField(controller: _pace, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Lari 1km — pace (menit/km, contoh 10.8)')),
          ],
        ]),
      ),
    ]);
  }

  Widget _result(bool isDark) {
    if (_generating || _generatedPlan == null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 88, height: 88,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: const LinearGradient(colors: [AppColors.accentDark, Color(0xFFC93D1D)])),
          child: const Center(child: Text('🤖', style: TextStyle(fontSize: 40))),
        ),
        const SizedBox(height: 24),
        const SizedBox(
          width: 28, height: 28,
          child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.accent),
        ),
        const SizedBox(height: 20),
        Text('AI menyusun plan kamu…', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Menganalisis profil → menentukan level →\nmemilih gerakan → menyusun jadwal', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight)),
      ]));
    }
    final plan = _generatedPlan!;
    final tier = plan['tier'] as String;
    final freq = plan['frequency'] as String;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Plan siap! 🎉', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.accentSoftLight, borderRadius: BorderRadius.circular(8)), child: Text(tier, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent))),
            ]),
            const SizedBox(height: 6),
            Text(freq, style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight)),
          ]),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: widget.onDone, child: const Text('Mulai Latihan 💪')),
      ]),
    );
  }

  bool get _canNext {
    switch (_step) {
      case 0: return true;
      case 1: return int.tryParse(_age.text.trim()) != null;
      case 2: return double.tryParse(_weight.text.trim()) != null;
      case 3: return double.tryParse(_height.text.trim()) != null;
      case 4: return true;
      case 5: return true; // boleh skip (tanpa alat)
      case 6: return true;
      default: return true;
    }
  }

  Future<void> _next() async {
    if (_step < 6) {
      setState(() => _step++);
      return;
    }
    // step 6 → generate plan via Mock AI
    setState(() { _generating = true; _step = 7; });
    await Future.delayed(const Duration(seconds: 2)); // "AI thinking" effect

    final gen = MockAiPlanGenerator(_lib);
    final profile = UserProfile(
      gender: _gender,
      age: int.tryParse(_age.text) ?? 25,
      weightKg: double.tryParse(_weight.text) ?? 70,
      heightCm: double.tryParse(_height.text) ?? 170,
      experience: _experience,
      equipment: _equipment,
      pushupMax: _skipTest ? null : int.tryParse(_pushup.text),
      squatMax: _skipTest ? null : int.tryParse(_squat.text),
      runPaceMinPerKm: _skipTest ? null : double.tryParse(_pace.text),
    );
    final plan = gen.generate(profile);
    final session = await _auth.currentUser();
    final email = session?['email'] ?? 'local';
    
    // Save plan & tier to SharedPreferences for Dashboard
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tier_$email', plan.tierName);
    await prefs.setString('plan_$email', jsonEncode({
      'tier': plan.tierName,
      'frequency': plan.frequency,
      'days': plan.days.map((d) => {
        'dayName': d.dayName,
        'focus': d.focus,
        'exercises': d.exercises.map((e) => {
          'id': e.exercise.id,
          'name': e.exercise.name,
          'sets': e.sets,
          'reps': e.reps,
          'rest': e.rest,
        }).toList(),
      }).toList(),
    }));

    // Sync to Supabase in background (if configured)
    final planMap = {
      'tier': plan.tierName,
      'frequency': plan.frequency,
      'days': plan.days.map((d) => {
        'dayName': d.dayName,
        'focus': d.focus,
        'exercises': d.exercises.map((e) => {
          'id': e.exercise.id,
          'name': e.exercise.name,
          'sets': e.sets,
          'reps': e.reps,
          'rest': e.rest,
        }).toList(),
      }).toList(),
    };
    SupabaseService.instance.saveUserMetrics(email, {
      'gender': _gender.name,
      'age': int.tryParse(_age.text) ?? 25,
      'weight': double.tryParse(_weight.text) ?? 70.0,
      'height': double.tryParse(_height.text) ?? 170.0,
      'experience': _experience.name,
      'pushup_count': int.tryParse(_pushup.text) ?? 0,
      'squat_count': int.tryParse(_squat.text) ?? 0,
      'pace': double.tryParse(_pace.text) ?? 0.0,
      'tier': plan.tierName,
    });
    SupabaseService.instance.saveWorkoutPlan(email, planMap);

    await _auth.setOnboarded(email);
    if (!mounted) return;
    setState(() {
      _generating = false;
      _generatedPlan = {'tier': plan.tierName, 'frequency': plan.frequency};
    });
  }

  Widget _opt(bool isDark, String label, bool sel, VoidCallback onTap) {
    final bgColor = sel
        ? (isDark ? AppColors.accentSoftDark : AppColors.accentSoftLight)
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final textColor = isDark ? AppColors.inkDark : AppColors.inkLight;
    final borderColor = sel
        ? (isDark ? AppColors.accentDark : AppColors.accent)
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: textColor))),
            if (sel) Icon(Icons.check_circle, color: isDark ? AppColors.accentDark : AppColors.accent, size: 20),
          ]),
        ),
      ),
    );
  }
}
