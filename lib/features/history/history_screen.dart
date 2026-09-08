import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../services/supabase_service.dart';

/// Screen menampilkan riwayat & progres latihan sebelumnya.
class HistoryScreen extends StatefulWidget {
  final VoidCallback? onStartWorkout;
  const HistoryScreen({super.key, this.onStartWorkout});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _logs = [];
  int _totalMinutes = 0;
  int _totalXp = 0;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void reload() {
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionRaw = prefs.getString('auth_session');
    String email = '';
    if (sessionRaw != null) {
      try {
        final session = jsonDecode(sessionRaw) as Map<String, dynamic>;
        email = session['email'] as String? ?? '';
      } catch (_) {}
    }
    if (email.isEmpty) {
      final cur = await SupabaseService.instance.currentUser();
      email = cur?['email'] ?? '';
    }

    final rawLogs = await SupabaseService.instance.getWorkoutLogs(email);

    int totalSec = 0;
    int totalXp = 0;

    for (final l in rawLogs) {
      final dur = (l['duration_seconds'] as num?)?.toInt() ??
          (l['durationSec'] as num?)?.toInt() ??
          0;
      totalSec += dur;

      final details = l['details'] as Map<String, dynamic>?;
      final xp = (details?['xpGained'] as num?)?.toInt() ??
          (l['xpGained'] as num?)?.toInt() ??
          50;
      totalXp += xp;
    }

    if (!mounted) return;
    setState(() {
      _logs = rawLogs;
      _totalMinutes = (totalSec / 60).round();
      if (_totalMinutes == 0 && rawLogs.isNotEmpty) {
        _totalMinutes = rawLogs.length * 15; // default estimate
      }
      _totalXp = totalXp;
      _loading = false;
    });
  }

  String _formatDate(String? isoStr) {
    if (isoStr == null) return 'Hari ini';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      final dayName = days[dt.weekday - 1];
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$dayName, ${dt.day} ${months[dt.month - 1]} ${dt.year} • $hour:$minute';
    } catch (_) {
      return 'Baru saja';
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds dtk';
    final mins = seconds ~/ 60;
    final remSecs = seconds % 60;
    if (remSecs == 0) return '$mins mnt';
    return '$mins mnt $remSecs dtk';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Riwayat & Progres',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _loading = true);
              _loadLogs();
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContentContainer(
          maxWidth: 680,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadLogs,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      // Header Stats Overview
                      _buildOverviewCard(isDark),
                      const SizedBox(height: 24),

                      // Section Title
                      Row(
                        children: [
                          Icon(Icons.history_rounded,
                              size: 20,
                              color: isDark ? AppColors.accentDark : AppColors.accent),
                          const SizedBox(width: 8),
                          Text(
                            'Catatan Sesi (${_logs.length})',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.inkDark : AppColors.inkLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Empty state or logs list
                      if (_logs.isEmpty)
                        _buildEmptyState(isDark)
                      else
                        ..._logs.map((log) => _buildLogCard(log, isDark)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Pencapaian',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Sesi Selesai',
                  val: '${_logs.length}',
                  color: isDark ? AppColors.accentDark : AppColors.accent,
                  isDark: isDark,
                ),
              ),
              Container(
                height: 36,
                width: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              Expanded(
                child: _statTile(
                  icon: Icons.timer_outlined,
                  label: 'Total Waktu',
                  val: '$_totalMinutes mnt',
                  color: Colors.blueAccent,
                  isDark: isDark,
                ),
              ),
              Container(
                height: 36,
                width: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              Expanded(
                child: _statTile(
                  icon: Icons.star_rounded,
                  label: 'Total XP',
                  val: '+$_totalXp',
                  color: Colors.amber,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String val,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          val,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.inkDark : AppColors.inkLight,
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

  Widget _buildEmptyState(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
              shape: BoxShape.circle,
            ),
            child: const Text('📋', style: TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Riwayat',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.inkDark : AppColors.inkLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Setiap sesi latihan yang kamu selesaikan akan otomatis tercatat dan tersinkron di sini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
            ),
          ),
          const SizedBox(height: 20),
          if (widget.onStartWorkout != null)
            FilledButton.icon(
              onPressed: widget.onStartWorkout,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Mulai Latihan Sekarang'),
            ),
        ],
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log, bool isDark) {
    final title = log['session_name']?.toString() ??
        log['sessionName']?.toString() ??
        'Sesi Latihan';
    final durSec = (log['duration_seconds'] as num?)?.toInt() ??
        (log['durationSec'] as num?)?.toInt() ??
        0;
    final dateStr = log['completed_at']?.toString() ?? log['date']?.toString();

    final details = log['details'] as Map<String, dynamic>?;
    final completedSets = details?['completedSets'] ?? log['completedSets'] ?? 0;
    final totalSets = details?['totalSets'] ?? log['totalSets'] ?? 0;
    final xp = details?['xpGained'] ?? log['xpGained'] ?? 50;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.accentDark : AppColors.accent)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text('💪', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.inkDark : AppColors.inkLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(dateStr),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.inkMutedDark
                            : AppColors.inkMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.accentSoftDark : AppColors.accentSoftLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+$xp XP',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.accentDark : AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricPill(
                icon: Icons.timer_outlined,
                label: 'Durasi',
                val: _formatDuration(durSec),
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _metricPill(
                icon: Icons.repeat_rounded,
                label: 'Set',
                val: '$completedSets / $totalSets Set',
                isDark: isDark,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Tersinkron',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricPill({
    required IconData icon,
    required String label,
    required String val,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13,
              color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight),
          const SizedBox(width: 5),
          Text(
            '$label: $val',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.inkDark : AppColors.inkLight,
            ),
          ),
        ],
      ),
    );
  }
}
