import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/navigation/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.instance.initialize();
  runApp(const CaliTrackerApp());
}

/// Root app — theme toggle + routing auth → onboard → dashboard.
class CaliTrackerApp extends StatefulWidget {
  const CaliTrackerApp({super.key});
  static final navKey = GlobalKey<NavigatorState>();
  @override State<CaliTrackerApp> createState() => _CaliTrackerAppState();
}

class _CaliTrackerAppState extends State<CaliTrackerApp> {
  final _auth = AuthService();
  ThemeMode _themeMode = ThemeMode.system;
  bool _loading = true;
  String? _userEmail;
  bool _onboarded = false;

  @override void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Support URL preview: ?view=dashboard or ?view=onboarding
    final view = Uri.base.queryParameters['view'];
    if (view == 'dashboard') {
      setState(() {
        _userEmail = 'preview@cali.id';
        _onboarded = true;
        _loading = false;
      });
      return;
    }
    final u = await _auth.currentUser();
    if (!mounted) return;
    if (u != null) {
      final ob = await _auth.isOnboarded(u['email']!);
      if (!mounted) return;
      setState(() { _userEmail = u['email']; _onboarded = ob; _loading = false; });
    } else {
      setState(() => _loading = false);
    }
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MaterialApp(
        theme: AppTheme.light(), darkTheme: AppTheme.dark(), themeMode: _themeMode,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp(
      key: CaliTrackerApp.navKey,
      title: 'Calisthenics Tracker',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      home: _userEmail == null
          ? LoginScreen(onSuccess: _checkSession)
          : !_onboarded
              ? OnboardingScreen(userEmail: _userEmail!, onDone: _checkSession)
              : MainShell(
                  toggleTheme: _toggleTheme,
                  themeMode: _themeMode,
                  onLogout: () async {
                    await _auth.logout();
                    _checkSession();
                  },
                ),
    );
  }
}
