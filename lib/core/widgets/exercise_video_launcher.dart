import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper utility for launching YouTube tutorial videos for calisthenics exercises.
class ExerciseVideoLauncher {
  /// Opens YouTube search results targeting form/execution tutorials for this exercise.
  static Future<bool> launchTutorial(BuildContext context, String exerciseName) async {
    final query = Uri.encodeComponent('how to do $exerciseName calisthenics tutorial form');
    final uri = Uri.parse('https://www.youtube.com/results?search_query=$query');

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback to platform default browser / in-app view
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tidak dapat membuka video: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red[700],
          ),
        );
      }
      return false;
    }
  }

  /// Reusable stylish button for exercise tutorial video.
  static Widget buildTutorialButton({
    required BuildContext context,
    required String exerciseName,
    bool compact = false,
  }) {
    if (compact) {
      return TextButton.icon(
        onPressed: () => launchTutorial(context, exerciseName),
        icon: const Icon(Icons.play_circle_fill_rounded, size: 18, color: Color(0xFFFF0000)),
        label: Text(
          'Video Form',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFF0000),
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          backgroundColor: const Color(0xFFFF0000).withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    return FilledButton.icon(
      onPressed: () => launchTutorial(context, exerciseName),
      icon: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
      label: Text(
        'Tonton Video Panduan di YouTube',
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFE62117), // YouTube brand red
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
