import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/exercise_video_launcher.dart';
import '../../services/ai/models/workout_plan.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];
  bool _loading = true;

  String _searchQuery = '';
  String _selectedCategory = 'all'; // all, push, pull, legs, core
  final String _selectedEquipment = 'all'; // all, none, pull_up_bar, etc.

  final List<String> _categories = ['all', 'push', 'pull', 'legs', 'core'];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      String raw = '';
      try {
        raw = await rootBundle.loadString('assets/data/exercise_library.json');
      } catch (_) {
        raw = await rootBundle.loadString('assets/assets/data/exercise_library.json');
      }

      final data = json.decode(raw) as Map<String, dynamic>;
      final exercisesMap = data['exercises'] as Map<String, dynamic>? ?? {};

      final list = <Exercise>[];
      for (final cat in exercisesMap.keys) {
        final catList = exercisesMap[cat] as List<dynamic>? ?? [];
        for (final item in catList) {
          list.add(Exercise.fromJson(item as Map<String, dynamic>));
        }
      }

      if (!mounted) return;
      setState(() {
        _allExercises.addAll(list);
        _filteredExercises = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredExercises = _allExercises.where((ex) {
        // Search query
        final matchQuery = _searchQuery.isEmpty ||
            ex.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            ex.muscles.any((m) => m.toLowerCase().contains(_searchQuery.toLowerCase()));

        // Category filter
        bool matchCat = true;
        if (_selectedCategory != 'all') {
          if (_selectedCategory == 'push') {
            matchCat = ex.id.startsWith('push_') || ex.muscles.contains('chest') || ex.muscles.contains('triceps');
          } else if (_selectedCategory == 'pull') {
            matchCat = ex.id.startsWith('pull_') || ex.muscles.contains('back') || ex.muscles.contains('biceps');
          } else if (_selectedCategory == 'legs') {
            matchCat = ex.id.startsWith('squat_') || ex.id.startsWith('lunge_') || ex.id.startsWith('calf_') || ex.muscles.contains('quads') || ex.muscles.contains('glutes');
          } else if (_selectedCategory == 'core') {
            matchCat = ex.id.startsWith('plank_') || ex.id.startsWith('crunch_') || ex.id.startsWith('leg_raise_') || ex.muscles.contains('core') || ex.muscles.contains('abs');
          }
        }

        // Equipment filter
        bool matchEquip = true;
        if (_selectedEquipment != 'all') {
          if (_selectedEquipment == 'none') {
            matchEquip = ex.equipment == 'none' || ex.equipment == 'wall' || ex.equipment == 'floor';
          } else {
            matchEquip = ex.equipment.contains(_selectedEquipment);
          }
        }

        return matchQuery && matchCat && matchEquip;
      }).toList();
    });
  }

  void _showExerciseDetail(Exercise ex, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Animation player slot
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Center(child: Text(ex.categoryIcon, style: const TextStyle(fontSize: 56))),
                ),
                const SizedBox(height: 20),

                // Name & Tier
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ex.name,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.inkDark : AppColors.inkLight,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.accentSoftDark : AppColors.accentSoftLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Level ${ex.level}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.accentDark : AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Muscle badges
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: ex.muscles.map((m) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Text(
                        m.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Instructions
                Text(
                  'Instruksi Gerakan',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.inkDark : AppColors.inkLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ex.instructions.isNotEmpty ? ex.instructions : 'Lakukan gerakan ini dengan kontrol tempo yang stabil dan pernapasan teratur.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
                  ),
                ),
                const SizedBox(height: 20),

                // Video Tutorial Launcher
                SizedBox(
                  width: double.infinity,
                  child: ExerciseVideoLauncher.buildTutorialButton(
                    context: context,
                    exerciseName: ex.name,
                  ),
                ),
                const SizedBox(height: 20),

                // Progression path info
                if (ex.progressionFrom != null || ex.progressionTo != null) ...[
                  Text(
                    'Jalur Progresi',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.inkDark : AppColors.inkLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        if (ex.progressionFrom != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sebelumnya:', style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight)),
                                Text(ex.progressionFrom!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        if (ex.progressionFrom != null && ex.progressionTo != null)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward_rounded, size: 16),
                          ),
                        if (ex.progressionTo != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Selanjutnya:', style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight)),
                                Text(ex.progressionTo!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Katalog Gerakan (${_filteredExercises.length})',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContentContainer(
          maxWidth: 680,
          child: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: TextField(
                  onChanged: (v) {
                    _searchQuery = v;
                    _applyFilter();
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari nama gerakan atau otot...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              // Category Pill Selector
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  itemBuilder: (ctx, i) {
                    final cat = _categories[i];
                    final active = _selectedCategory == cat;
                    final label = cat == 'all'
                        ? 'Semua'
                        : cat == 'push'
                            ? 'Dada & Tricep'
                            : cat == 'pull'
                                ? 'Punggung & Bicep'
                                : cat == 'legs'
                                    ? 'Kaki'
                                    : 'Core / Perut';

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: active,
                        label: Text(label),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? Colors.white : (isDark ? AppColors.inkDark : AppColors.inkLight),
                        ),
                        backgroundColor: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
                        selectedColor: isDark ? AppColors.accentDark : AppColors.accent,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide.none,
                        onSelected: (_) {
                          _selectedCategory = cat;
                          _applyFilter();
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Exercise List
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredExercises.isEmpty
                        ? Center(
                            child: Text(
                              'Tidak ada gerakan yang cocok',
                              style: GoogleFonts.inter(
                                color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                            itemCount: _filteredExercises.length,
                            itemBuilder: (ctx, i) {
                              final ex = _filteredExercises[i];
                              return _buildExerciseListItem(ex, isDark);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseListItem(Exercise ex, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        onTap: () => _showExerciseDetail(ex, isDark),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Text(ex.categoryIcon, style: const TextStyle(fontSize: 22))),
        ),
        title: Text(
          ex.name,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.inkDark : AppColors.inkLight,
          ),
        ),
        subtitle: Text(
          'Target: ${ex.targetReps} • Alat: ${ex.equipment.replaceAll('_', ' ')}',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? AppColors.accentSoftDark : AppColors.accentSoftLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Lvl ${ex.level}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.accentDark : AppColors.accent,
            ),
          ),
        ),
      ),
    );
  }
}
