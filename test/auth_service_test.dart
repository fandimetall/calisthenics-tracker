import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calisthenics_tracker/services/auth_service.dart';
import 'package:calisthenics_tracker/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Local Auth Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      SupabaseService.instance.resetForTesting();
      await SupabaseService.instance.initialize(forceOffline: true);
    });

    test('Register succeeds for new user and fails for duplicate', () async {
      final auth = AuthService();
      final ok1 = await auth.register(name: 'Fandi', email: 'test@cali.id', password: 'password123');
      expect(ok1.status, equals(RegisterStatus.success));

      final ok2 = await auth.register(name: 'Fandi 2', email: 'test@cali.id', password: 'password456');
      expect(ok2.status, equals(RegisterStatus.emailAlreadyInUse));
    });

    test('Login succeeds with correct password and fails with wrong', () async {
      final auth = AuthService();
      await auth.register(name: 'Fandi', email: 'fandi@cali.id', password: 'secretpassword');

      final okWrong = await auth.login(email: 'fandi@cali.id', password: 'wrongpassword');
      expect(okWrong, isFalse);

      final okCorrect = await auth.login(email: 'fandi@cali.id', password: 'secretpassword');
      expect(okCorrect, isTrue);

      final user = await auth.currentUser();
      expect(user, isNotNull);
      expect(user!['email'], equals('fandi@cali.id'));
      expect(user['name'], equals('Fandi'));
    });

    test('Onboarding status flag saves and retrieves correctly', () async {
      final auth = AuthService();
      expect(await auth.isOnboarded('user1@cali.id'), isFalse);

      await auth.setOnboarded('user1@cali.id');
      expect(await auth.isOnboarded('user1@cali.id'), isTrue);
    });

    test('Logout clears current session but keeps user registered', () async {
      final auth = AuthService();
      await auth.register(name: 'Fandi', email: 'fandi@cali.id', password: 'secretpassword');
      expect(await auth.currentUser(), isNotNull);

      await auth.logout();
      expect(await auth.currentUser(), isNull);

      // Login again succeeds
      final reLogin = await auth.login(email: 'fandi@cali.id', password: 'secretpassword');
      expect(reLogin, isTrue);
    });
  });
}
