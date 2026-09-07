import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum RegisterStatus {
  success,
  needsEmailConfirmation,
  emailAlreadyInUse,
  error,
}

class RegisterOutcome {
  final RegisterStatus status;
  final String? message;
  const RegisterOutcome(this.status, [this.message]);
}

/// Phase 4: Hybrid Supabase + Offline-First Service
/// Works with live Supabase credentials, or gracefully falls back
/// to local storage (SharedPreferences) when credentials are not configured.
class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  bool _initialized = false;
  bool _isLive = false;

  bool get isLive => _isLive;

  /// Compile-time or runtime environment variables with project defaults
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kbmldbqnkjkrspbjcoyo.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_u5BIcS6gpR-qw-9JDNzxWw_7pVgq__O',
  );

  /// Reset instance state for isolated unit testing
  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    _isLive = false;
  }

  /// Initialize Supabase if credentials are provided.
  Future<void> initialize({String? url, String? anonKey, bool forceOffline = false}) async {
    if (_initialized) return;

    if (forceOffline) {
      _isLive = false;
      _initialized = true;
      return;
    }

    final targetUrl = url ?? supabaseUrl;
    final targetKey = anonKey ?? supabaseAnonKey;

    if (targetUrl.isNotEmpty && targetKey.isNotEmpty) {
      try {
        await Supabase.initialize(
          url: targetUrl,
          // ignore: deprecated_member_use
          anonKey: targetKey,
          debug: kDebugMode,
        );
        _isLive = true;
      } catch (e) {
        debugPrint('Supabase init failed, falling back to local: $e');
        _isLive = false;
      }
    } else {
      _isLive = false;
    }
    _initialized = true;
  }

  SupabaseClient? get _client => _isLive ? Supabase.instance.client : null;

  // ---------------------------------------------------------------------------
  // Auth Operations
  // ---------------------------------------------------------------------------

  Stream<AuthState>? get onAuthStateChange => _client?.auth.onAuthStateChange;

  Future<RegisterOutcome> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_isLive && _client != null) {
      try {
        final res = await _client!.auth.signUp(
          email: email,
          password: password,
          data: {'name': name},
        );
        if (res.user == null) {
          return const RegisterOutcome(RegisterStatus.error, 'Gagal mendaftar. Silakan coba lagi.');
        }

        // Check if email confirmation is required
        if (res.session == null) {
          return const RegisterOutcome(
            RegisterStatus.needsEmailConfirmation,
            'Tautan verifikasi telah dikirim ke email Anda.',
          );
        }

        return const RegisterOutcome(RegisterStatus.success);
      } on AuthException catch (ae) {
        debugPrint('Supabase AuthException: ${ae.message}');
        if (ae.message.toLowerCase().contains('already registered') ||
            ae.statusCode == '422' ||
            ae.code == 'user_already_exists') {
          return const RegisterOutcome(
            RegisterStatus.emailAlreadyInUse,
            'Email sudah terdaftar. Silakan pilih tab Masuk.',
          );
        }
        return RegisterOutcome(RegisterStatus.error, ae.message);
      } catch (e) {
        debugPrint('Supabase signUp error: $e');
        return RegisterOutcome(RegisterStatus.error, e.toString());
      }
    }

    // Local fallback
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('auth_users');
    final users = raw == null ? <String, dynamic>{} : json.decode(raw) as Map<String, dynamic>;
    if (users.containsKey(email)) {
      return const RegisterOutcome(
        RegisterStatus.emailAlreadyInUse,
        'Email sudah terdaftar. Silakan pilih tab Masuk.',
      );
    }
    users[email] = {'password': password, 'name': name};
    await sp.setString('auth_users', json.encode(users));
    await sp.setString('auth_session', json.encode({'email': email, 'name': name}));
    return const RegisterOutcome(RegisterStatus.success);
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    if (_isLive && _client != null) {
      try {
        final res = await _client!.auth.signInWithPassword(
          email: email,
          password: password,
        );
        return res.user != null;
      } catch (e) {
        debugPrint('Supabase signIn error: $e');
        return false;
      }
    }

    // Local fallback
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('auth_users');
    if (raw == null) return false;
    final users = json.decode(raw) as Map<String, dynamic>;
    final u = users[email];
    if (u == null || u['password'] != password) return false;
    await sp.setString('auth_session', json.encode({'email': email, 'name': u['name']}));
    return true;
  }

  Future<void> logout() async {
    if (_isLive && _client != null) {
      try {
        await _client!.auth.signOut();
      } catch (_) {}
    }
    final sp = await SharedPreferences.getInstance();
    await sp.remove('auth_session');
  }

  Future<Map<String, String>?> currentUser() async {
    if (_isLive && _client != null) {
      final u = _client!.auth.currentUser;
      if (u != null) {
        return {
          'id': u.id,
          'email': u.email ?? '',
          'name': u.userMetadata?['name']?.toString() ?? '',
        };
      }
    }

    // Local fallback or pending-confirmation session
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString('auth_session');
      if (raw == null) return null;
      final d = json.decode(raw) as Map<String, dynamic>;
      final email = d['email']?.toString();
      if (email == null) return null;
      return {
        'id': 'local_${email.hashCode}',
        'email': email,
        'name': d['name']?.toString() ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Data Sync & Storage (Metrics, Plans, Workout Logs)
  // ---------------------------------------------------------------------------

  Future<void> saveUserMetrics(String email, Map<String, dynamic> metrics) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('user_metrics_$email', json.encode(metrics));

    if (_isLive && _client != null) {
      final user = _client!.auth.currentUser;
      if (user != null) {
        try {
          await _client!.from('user_metrics').upsert({
            'user_id': user.id,
            'gender': metrics['gender'],
            'age': metrics['age'],
            'weight': metrics['weight'],
            'height': metrics['height'],
            'experience': metrics['experience'],
            'pushup_count': metrics['pushup_count'],
            'squat_count': metrics['squat_count'],
            'pace': metrics['pace'],
            'tier': metrics['tier'],
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Sync metrics to Supabase failed: $e');
        }
      }
    }
  }

  Future<void> saveWorkoutPlan(String email, Map<String, dynamic> plan) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('active_workout_plan_$email', json.encode(plan));

    if (_isLive && _client != null) {
      final user = _client!.auth.currentUser;
      if (user != null) {
        try {
          await _client!.from('workout_plans').insert({
            'user_id': user.id,
            'plan_data': plan,
            'is_active': true,
          });
        } catch (e) {
          debugPrint('Sync plan to Supabase failed: $e');
        }
      }
    }
  }

  Future<void> logWorkoutSession({
    required String email,
    required String sessionName,
    required int durationSeconds,
    Map<String, dynamic>? details,
  }) async {
    final sp = await SharedPreferences.getInstance();
    final key = 'workout_history_$email';
    final existingRaw = sp.getStringList(key) ?? [];
    final entry = {
      'session_name': sessionName,
      'duration_seconds': durationSeconds,
      'completed_at': DateTime.now().toIso8601String(),
      'details': details ?? {},
    };
    existingRaw.add(json.encode(entry));
    await sp.setStringList(key, existingRaw);

    if (_isLive && _client != null) {
      final user = _client!.auth.currentUser;
      if (user != null) {
        try {
          await _client!.from('workout_logs').insert({
            'user_id': user.id,
            'session_name': sessionName,
            'duration_seconds': durationSeconds,
            'details': details,
          });
        } catch (e) {
          debugPrint('Sync workout log to Supabase failed: $e');
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> getWorkoutLogs(String email) async {
    if (_isLive && _client != null) {
      final user = _client!.auth.currentUser;
      if (user != null) {
        try {
          final res = await _client!
              .from('workout_logs')
              .select()
              .eq('user_id', user.id)
              .order('completed_at', ascending: false);
          return List<Map<String, dynamic>>.from(res);
        } catch (_) {}
      }
    }

    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList('workout_history_$email') ?? [];
    return list.map((e) => json.decode(e) as Map<String, dynamic>).toList();
  }
}
