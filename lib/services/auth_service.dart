import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

/// Auth facade — delegates to SupabaseService (live or local fallback).
/// Screen-level API stays identical; no screen changes needed.
class AuthService {
  final _supa = SupabaseService.instance;

  Future<bool> register({
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

  /// Onboarding status flag per user
  Future<bool> isOnboarded(String email) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool('onboarded_$email') ?? false;
  }

  Future<void> setOnboarded(String email) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('onboarded_$email', true);
  }
}
