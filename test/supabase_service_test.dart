import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calisthenics_tracker/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SupabaseService Local Fallback', () {
    late SupabaseService svc;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      svc = SupabaseService.instance;
      svc.resetForTesting();
      await svc.initialize(forceOffline: true);
    });

    test('Initializes in offline mode when no credentials provided', () {
      expect(svc.isLive, isFalse);
    });

    test('Register + login cycle works in local fallback', () async {
      final ok = await svc.register(
        name: 'Test User',
        email: 'test@local.id',
        password: 'pass123',
      );
      expect(ok.status, equals(RegisterStatus.success));

      // Duplicate fails
      final dup = await svc.register(
        name: 'Dup',
        email: 'test@local.id',
        password: 'pass456',
      );
      expect(dup.status, equals(RegisterStatus.emailAlreadyInUse));

      // Login with wrong password fails
      final bad = await svc.login(email: 'test@local.id', password: 'wrong');
      expect(bad, isFalse);

      // Login with correct password succeeds
      final good = await svc.login(email: 'test@local.id', password: 'pass123');
      expect(good, isTrue);

      final user = await svc.currentUser();
      expect(user, isNotNull);
      expect(user!['email'], 'test@local.id');
      expect(user['name'], 'Test User');
    });

    test('Logout clears session', () async {
      await svc.register(name: 'X', email: 'x@t.id', password: 'p');
      expect(await svc.currentUser(), isNotNull);

      await svc.logout();
      expect(await svc.currentUser(), isNull);
    });

    test('Save and retrieve workout logs locally', () async {
      await svc.logWorkoutSession(
        email: 'log@t.id',
        sessionName: 'Push Day',
        durationSeconds: 1800,
        details: {'sets': 12, 'xp': 50},
      );
      await svc.logWorkoutSession(
        email: 'log@t.id',
        sessionName: 'Pull Day',
        durationSeconds: 2400,
      );

      final logs = await svc.getWorkoutLogs('log@t.id');
      expect(logs.length, 2);
      expect(logs[0]['session_name'], 'Push Day');
      expect(logs[0]['duration_seconds'], 1800);
      expect(logs[1]['session_name'], 'Pull Day');
    });

    test('Save user metrics locally', () async {
      // Should not throw
      await svc.saveUserMetrics('m@t.id', {
        'gender': 'male',
        'age': 27,
        'weight': 86.0,
        'height': 169.5,
        'tier': 'Tier 1',
      });

      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString('user_metrics_m@t.id');
      expect(raw, isNotNull);
    });
  });
}
