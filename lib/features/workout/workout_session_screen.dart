import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/exercise_video_launcher.dart';
import '../../services/supabase_service.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final Map<String, dynamic>? workoutDay;
  final VoidCallback? onFinished;

  const WorkoutSessionScreen({
    super.key,
    this.workoutDay,
    this.onFinished,
  });

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  // Session stopwatch
  late final Stopwatch _stopwatch;
  late final Timer _timer;
  int _elapsedSeconds = 0;

  // Rest timer
  int _restSecondsRemaining = 0;
  Timer? _restTimer;
  bool _isResting = false;

  // Exercise tracking state: Map<exerciseIndex, Set<setIndex>>
  final Map<int, Set<int>> _completedSets = {};
  late List<dynamic> _exercises;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _elapsedSeconds = _stopwatch.elapsed.inSeconds);
      }
    });

    _initExercises();
  }

  void _initExercises() {
    if (widget.workoutDay != null && widget.workoutDay!['exercises'] != null) {
      _exercises = widget.workoutDay!['exercises'] as List<dynamic>;
    } else {
      // Default fallback workout if accessed directly
      _exercises = [
        {
          'id': 'push_wall',
          'name': 'Wall Push-up',
          'sets': 3,
          'reps': '10-15',
          'rest': 60,
          'muscles': ['chest', 'triceps', 'shoulders'],
          'instructions': 'Dorong badan dari dinding dengan postur lurus dan kontrol tempo.',
        },
        {
          'id': 'squat_box',
          'name': 'Box Squat',
          'sets': 3,
          'reps': '10-12',
          'rest': 60,
          'muscles': ['quads', 'glutes'],
          'instructions': 'Jongkok perlahan sampai menyentuh kursi, lalu dorong kembali naik.',
        },
        {
          'id': 'plank_knee',
          'name': 'Knee Plank',
          'sets': 3,
          'reps': '20s',
          'rest': 45,
          'muscles': ['core', 'abs'],
          'instructions': 'Tahan posisi plank bertumpu pada lutut, kencangkan perut.',
        },
      ];
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _restTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restSecondsRemaining = seconds;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_restSecondsRemaining > 1) {
        setState(() => _restSecondsRemaining--);
      } else {
        timer.cancel();
        setState(() {
          _isResting = false;
          _restSecondsRemaining = 0;
        });
      }
    });
  }

  void _toggleSet(int exIdx, int setIdx, int restSeconds) {
    setState(() {
      _completedSets.putIfAbsent(exIdx, () => <int>{});
      if (_completedSets[exIdx]!.contains(setIdx)) {
        _completedSets[exIdx]!.remove(setIdx);
      } else {
        _completedSets[exIdx]!.add(setIdx);
        // Start rest timer automatically when set completed
        _startRestTimer(restSeconds > 0 ? restSeconds : 60);
      }
    });
  }

  String _formatTime(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get _totalSets {
    int count = 0;
    for (final ex in _exercises) {
      count += (ex['sets'] as num? ?? 3).toInt();
    }
    return count;
  }

  int get _completedSetsCount {
    int count = 0;
    for (final set in _completedSets.values) {
      count += set.length;
    }
    return count;
  }

  Future<void> _finishWorkout() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionRaw = prefs.getString('auth_session');
    String email = 'local';
    if (sessionRaw != null) {
      try {
        final d = json.decode(sessionRaw) as Map<String, dynamic>;
        email = d['email']?.toString() ?? 'local';
      } catch (_) {}
    }

    // Award +50 XP and increment streak if today is fresh
    final currentXp = prefs.getInt('xp_$email') ?? 0;
    final newXp = currentXp + 50;
    await prefs.setInt('xp_$email', newXp);

    final currentStreak = prefs.getInt('streak_$email') ?? 0;
    final newStreak = currentStreak + 1;
    await prefs.setInt('streak_$email', newStreak);

    // Save session to history
    final historyList = prefs.getStringList('history_$email') ?? [];
    historyList.add(json.encode({
      'date': DateTime.now().toIso8601String(),
      'durationSec': _elapsedSeconds,
      'completedSets': _completedSetsCount,
      'totalSets': _totalSets,
      'xpGained': 50,
    }));
    await prefs.setStringList('history_$email', historyList);

    // Sync session to Supabase in background
    SupabaseService.instance.logWorkoutSession(
      email: email,
      sessionName: widget.workoutDay?['dayName']?.toString() ?? 'Quick Workout',
      durationSeconds: _elapsedSeconds,
      details: {
        'completedSets': _completedSetsCount,
        'totalSets': _totalSets,
        'xpGained': 50,
      },
    );

    if (!mounted) return;

    // Show celebratory dialog
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          title: Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.accentSoftDark : AppColors.accentSoftLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🏆', style: TextStyle(fontSize: 40)),
                ),
                const SizedBox(height: 14),
                Text(
                  'Latihan Selesai!',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: isDark ? AppColors.inkDark : AppColors.inkLight,
                  ),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Kerja bagus! Konsistensimu membangun tubuh yang lebih kuat setiap hari.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('Durasi', _formatTime(_elapsedSeconds), isDark),
                    _statItem('Set Selesai', '$_completedSetsCount / $_totalSets', isDark),
                    _statItem('XP Diperoleh', '+50 XP', isDark, isAccent: true),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (widget.onFinished != null) {
                    widget.onFinished!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Kembali ke Dashboard'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statItem(String label, String value, bool isDark, {bool isAccent = false}) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isAccent
                ? (isDark ? AppColors.accentDark : AppColors.accent)
                : (isDark ? AppColors.inkDark : AppColors.inkLight),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _totalSets > 0 ? _completedSetsCount / _totalSets : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.workoutDay?['focus'] ?? 'Sesi Latihan',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_elapsedSeconds),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? AppColors.inkDark : AppColors.inkLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContentContainer(
          maxWidth: 680,
          child: Column(
            children: [
              // Overall Progress Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progres Sesi',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
                          ),
                        ),
                        Text(
                          '$_completedSetsCount dari $_totalSets set selesai',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.accentDark : AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
                        valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),

              // Rest timer overlay if active
              if (_isResting)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.accentSoftDark : AppColors.accentSoftLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.accentDark : AppColors.accent,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('⏳', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Waktu Istirahat',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.inkDark : AppColors.inkLight,
                              ),
                            ),
                            Text(
                              'Atur napas & minum air sedikit',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_restSecondsRemaining}s',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.accentDark : AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 20),
                        tooltip: 'Lewati istirahat',
                        onPressed: () {
                          _restTimer?.cancel();
                          setState(() => _isResting = false);
                        },
                      ),
                    ],
                  ),
                ),

              // Exercise List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                  itemCount: _exercises.length,
                  itemBuilder: (ctx, i) {
                    final ex = _exercises[i] as Map<String, dynamic>;
                    return _buildExerciseCard(ex, i, isDark);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _completedSetsCount > 0 ? _finishWorkout : null,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: const Text('Selesai Latihan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> ex, int exIdx, bool isDark) {
    final name = ex['name'] as String? ?? 'Exercise';
    final sets = (ex['sets'] as num? ?? 3).toInt();
    final reps = ex['reps']?.toString() ?? '10';
    final rest = (ex['rest'] as num? ?? 60).toInt();
    final instructions = ex['instructions'] as String? ?? '';
    final completedSetIndices = _completedSets[exIdx] ?? <int>{};

    final id = ex['id']?.toString() ?? '';
    String exIcon = '🤸';
    if (id.startsWith('push_')) {
      exIcon = '💪';
    } else if (id.startsWith('pull_')) {
      exIcon = '🧗';
    } else if (id.startsWith('squat_') || id.startsWith('lunge_')) {
      exIcon = '🦵';
    } else if (id.startsWith('plank_') || id.startsWith('crunch_')) {
      exIcon = '🎯';
    } else if (id.startsWith('warmup_')) {
      exIcon = '🔥';
    } else if (id.startsWith('cooldown_')) {
      exIcon = '🧘';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header exercise with Lottie animation slot placeholder
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animation Preview Slot
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Center(
                    child: Text(exIcon, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.inkDark : AppColors.inkLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$sets Set • $reps • Rest ${rest}s',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.accentDark : AppColors.accent,
                        ),
                      ),
                      if (instructions.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          instructions,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      ExerciseVideoLauncher.buildTutorialButton(
                        context: context,
                        exerciseName: name,
                        compact: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Sets Checklist Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: List.generate(sets, (sIdx) {
                final isDone = completedSetIndices.contains(sIdx);
                return InkWell(
                  onTap: () => _toggleSet(exIdx, sIdx, rest),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isDone
                                ? (isDark ? AppColors.accentDark : AppColors.accent)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDone
                                  ? (isDark ? AppColors.accentDark : AppColors.accent)
                                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
                              width: 1.5,
                            ),
                          ),
                          child: isDone
                              ? const Icon(Icons.check, size: 18, color: Colors.white)
                              : Center(
                                  child: Text(
                                    '${sIdx + 1}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Set ${sIdx + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.inkDark : AppColors.inkLight,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          reps,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
