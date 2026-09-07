import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/responsive_layout.dart';

/// Dashboard utama — streak, level/XP, today workout, weekly chart.
class DashboardScreen extends StatefulWidget {
  final VoidCallback? toggleTheme;
  final ThemeMode? mode;
  final VoidCallback? onLogout;
  final void Function(Map<String, dynamic>? workoutDay)? onStartWorkout;
  const DashboardScreen({
    super.key,
    this.toggleTheme,
    this.mode,
    this.onLogout,
    this.onStartWorkout,
  });
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Mock data — nanti diganti data dari SharedPreferences / SQLite
  int _streak = 0;
  int _level = 1;
  int _xp = 0;
  final int _xpToNext = 100; // ponytail: hardcoded, derive from level formula when leveling logic lands
  String _tierName = 'Beginner';
  String _todayFocus = 'Full Body';
  int _todayExerciseCount = 0;
  Map<String, dynamic>? _todayWorkoutDay;
  List<double> _weeklyMinutes = [0, 0, 0, 0, 0, 0, 0]; // Sen-Min
  String _userName = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    // Auth service stores session as JSON in 'auth_session'
    final sessionRaw = prefs.getString('auth_session');
    String email = '';
    String name = '';
    if (sessionRaw != null) {
      final session = jsonDecode(sessionRaw) as Map<String, dynamic>;
      email = session['email'] as String? ?? '';
      name = session['name'] as String? ?? email.split('@').first;
    }
    final streak = prefs.getInt('streak_$email') ?? 0;
    final level = prefs.getInt('level_$email') ?? 1;
    final xp = prefs.getInt('xp_$email') ?? 0;
    final tier = prefs.getString('tier_$email') ?? 'Beginner';

    // Mock weekly data (nanti diganti log real)
    final weeklyRaw = prefs.getStringList('weekly_minutes_$email');
    List<double> weekly = [0, 25, 30, 0, 40, 20, 0]; // demo data
    if (weeklyRaw != null && weeklyRaw.length == 7) {
      weekly = weeklyRaw.map((e) => double.tryParse(e) ?? 0).toList();
    }

    // Count today's exercises from plan
    int todayCount = 5; // default demo
    String focus = 'Full Body';
    try {
      final planJson = prefs.getString('plan_$email');
      if (planJson != null) {
        final plan = jsonDecode(planJson) as Map<String, dynamic>;
        final days = plan['days'] as List? ?? [];
        if (days.isNotEmpty) {
          // Pick first day as "today" for demo
          final day = days[0] as Map<String, dynamic>;
          focus = day['focus'] as String? ?? 'Full Body';
          todayCount = (day['exercises'] as List?)?.length ?? 5;
          _todayWorkoutDay = day;
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _userName = name;
      _streak = streak;
      _level = level;
      _xp = xp;
      _tierName = tier;
      _todayFocus = focus;
      _todayExerciseCount = todayCount;
      _weeklyMinutes = weekly;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SafeArea(
        child: ResponsiveContentContainer(
          maxWidth: 680,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDark),
                const SizedBox(height: 20),
                _buildStreakCard(isDark),
                const SizedBox(height: 16),
                _buildLevelCard(isDark),
                const SizedBox(height: 16),
                _buildTodayCard(isDark),
                const SizedBox(height: 16),
                _buildWeeklyChart(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header — greeting + theme toggle + logout
  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, $_userName 👋',
                style: GoogleFonts.inter(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.inkDark : AppColors.inkLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _tierName,
                style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.accentDark : AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        // Theme toggle
        if (widget.toggleTheme != null)
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(children: [
              _themePill('☀️', widget.mode != ThemeMode.dark, isDark, () {
                if (widget.mode == ThemeMode.dark) widget.toggleTheme!();
              }),
              _themePill('🌙', widget.mode == ThemeMode.dark, isDark, () {
                if (widget.mode != ThemeMode.dark) widget.toggleTheme!();
              }),
            ]),
          ),
        const SizedBox(width: 8),
        if (widget.onLogout != null)
          IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout, size: 20)),
      ],
    );
  }

  Widget _themePill(String emoji, bool active, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 30,
        decoration: BoxDecoration(
          color: active
              ? (isDark ? AppColors.surfaceDark : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  /// Streak card — fire icon + jumlah hari
  Widget _buildStreakCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF331F18), const Color(0xFF1C1F23)]
              : [const Color(0xFFFDEDE8), const Color(0xFFFFF7F5)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFFFD4C7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.accentDark : AppColors.accent).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Text('🔥', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_streak Hari Streak',
                  style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.inkDark : AppColors.inkLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _streak > 0 ? 'Lanjut terus! 💪' : 'Mulai latihan hari ini!',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Level + XP bar
  Widget _buildLevelCard(bool isDark) {
    final progress = _xpToNext > 0 ? (_xp / _xpToNext).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.accentDark : AppColors.accent).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$_level',
                  style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.accentDark : AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Level $_level', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.inkDark : AppColors.inkLight)),
                    Text('$_xp / $_xpToNext XP', style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight)),
                  ],
                ),
              ),
              Icon(Icons.star_rounded, color: isDark ? AppColors.accentDark : AppColors.accent, size: 28),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
              valueColor: AlwaysStoppedAnimation(isDark ? AppColors.accentDark : AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  /// Today workout card — tombol mulai latihan
  Widget _buildTodayCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                'Latihan Hari Ini',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.inkDark : AppColors.inkLight),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoChip(isDark, Icons.track_changes, _todayFocus),
              const SizedBox(width: 8),
              _infoChip(isDark, Icons.format_list_numbered, '$_todayExerciseCount gerakan'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => widget.onStartWorkout?.call(_todayWorkoutDay),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Mulai Latihan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(bool isDark, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.inkDark : AppColors.inkLight)),
        ],
      ),
    );
  }

  /// Weekly chart — native bar chart (no fl_chart dependency)
  Widget _buildWeeklyChart(bool isDark) {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final maxY = _weeklyMinutes.fold<double>(0, (a, b) => a > b ? a : b);
    final ceiling = maxY < 10 ? 60.0 : maxY;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, size: 20),
              const SizedBox(width: 8),
              Text('Minggu Ini', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.inkDark : AppColors.inkLight)),
              const Spacer(),
              Text(
                '${_weeklyMinutes.fold<double>(0, (a, b) => a + b).round()} menit',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.accentDark : AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final val = _weeklyMinutes[i];
                final ratio = ceiling > 0 ? (val / ceiling).clamp(0.0, 1.0) : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${val.round()}',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight),
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          height: ratio * 120,
                          decoration: BoxDecoration(
                            color: val > 0
                                ? (isDark ? AppColors.accentDark : AppColors.accent)
                                : (isDark ? AppColors.surface2Dark : AppColors.surface2Light),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          days[i],
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight),
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
