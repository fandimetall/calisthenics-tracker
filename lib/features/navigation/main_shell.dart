import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../library/exercise_library_screen.dart';
import '../workout/workout_session_screen.dart';

/// Main navigation shell — Bottom Navigation Bar + page switching.
class MainShell extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback? toggleTheme;
  final ThemeMode? themeMode;
  const MainShell({
    super.key,
    required this.onLogout,
    this.toggleTheme,
    this.themeMode,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _openWorkoutSession({Map<String, dynamic>? workoutDay}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutSessionScreen(
          workoutDay: workoutDay,
          onFinished: () {
            Navigator.of(context).pop();
            // Force refresh dashboard
            setState(() => _currentIndex = 0);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(
            toggleTheme: widget.toggleTheme,
            mode: widget.themeMode,
            onLogout: widget.onLogout,
            onStartWorkout: (workoutDay) => _openWorkoutSession(workoutDay: workoutDay),
          ),
          const ExerciseLibraryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        indicatorColor: isDark ? AppColors.accentSoftDark : AppColors.accentSoftLight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: isDark ? AppColors.accentDark : AppColors.accent),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: const Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center_rounded, color: isDark ? AppColors.accentDark : AppColors.accent),
            label: 'Katalog',
          ),
        ],
      ),
    );
  }
}
