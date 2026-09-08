import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Auth facade — delegates to SupabaseService (live or local fallback).
/// Screen-level API stays identical; no screen changes needed.
class AuthService {
  final _supa = SupabaseService.instance;

  Stream<AuthState>? get onAuthStateChange => _supa.onAuthStateChange;

  Future<RegisterOutcome> register({
    required String name,
    required String email,
    required String password,
  }) => _supa.register(name: name, email: email, password: password);

  Future<bool> login({
    required String email,
    required String password,
  }) => _supa.login(email: email, password: password);

  Future<void> logout() => _supa.logout();

  Future<Map<String, String>?> currentUser() => _supa.currentUser();

  /// Onboarding status flag per user (checks local storage and Supabase Cloud fallback)
  Future<bool> isOnboarded(String email) async {
    final sp = await SharedPreferences.getInstance();
    final local = sp.getBool('onboarded_$email') ?? false;
    if (local) return true;

    // Check if user already completed onboarding on Supabase Cloud
    final metrics = await _supa.getUserMetrics(email);
    if (metrics != null && metrics.isNotEmpty) {
      await sp.setBool('onboarded_$email', true);
      // Restore plan if missing locally
      final plan = await _supa.getActiveWorkoutPlan(email);
      if (plan != null) {
        await sp.setString('plan_$email', json.encode(plan));
        await sp.setString('active_workout_plan_$email', json.encode(plan));
        if (plan['tier'] != null) {
          await sp.setString('tier_$email', plan['tier'].toString());
        }
      }
      return true;
    }
    return false;
  }

  Future<void> setOnboarded(String email) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('onboarded_$email', true);
  }
}
