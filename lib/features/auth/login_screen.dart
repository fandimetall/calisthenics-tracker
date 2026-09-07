import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../services/auth_service.dart';

/// Unified Auth Screen — Masuk & Daftar dalam satu tampilan (no Navigator stack bugs).
class LoginScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  final bool initialRegister;
  const LoginScreen({
    super.key,
    required this.onSuccess,
    this.initialRegister = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late bool _isRegister;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _auth = AuthService();

  String? _error;
  bool _loading = false;
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialRegister;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _switchMode(bool register) {
    setState(() {
      _isRegister = register;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveCard(
          maxWidth: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBrandHeader(isDark),
              const SizedBox(height: 28),

              // Segmented Tab Toggle (Masuk vs Daftar)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _tabButton(
                        label: 'Masuk',
                        active: !_isRegister,
                        isDark: isDark,
                        onTap: () => _switchMode(false),
                      ),
                    ),
                    Expanded(
                      child: _tabButton(
                        label: 'Daftar Baru',
                        active: _isRegister,
                        isDark: isDark,
                        onTap: () => _switchMode(true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                _isRegister ? 'Buat Akun Baru' : 'Selamat Datang',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? AppColors.inkDark : AppColors.inkLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isRegister
                    ? 'Mulai perjalanan kalistenik & latihan dari rumah 🔥'
                    : 'Lanjutkan progres latihan & streak harianmu 💪',
                style: GoogleFonts.inter(
                  color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Field Nama (hanya saat daftar)
              if (_isRegister) ...[
                _buildLabel(isDark, 'Nama Panggilan / Lengkap'),
                const SizedBox(height: 6),
                TextField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Misal: Fandi',
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      size: 20,
                      color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Field Email
              _buildLabel(isDark, 'Email'),
              const SizedBox(height: 6),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'nama@email.com',
                  prefixIcon: Icon(
                    Icons.mail_outline_rounded,
                    size: 20,
                    color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Field Password
              _buildLabel(isDark, 'Password'),
              const SizedBox(height: 6),
              TextField(
                controller: _pass,
                obscureText: _obscurePass,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: _isRegister ? 'Minimal 6 karakter' : '••••••••',
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
                    ),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
              ),

              // Error Box
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.inter(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Submit Button
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  elevation: 0,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        _isRegister ? 'Daftar Sekarang' : 'Masuk ke Akun',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
              const SizedBox(height: 18),

              // Bottom switcher text
              Center(
                child: TextButton(
                  onPressed: () => _switchMode(!_isRegister),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
                      ),
                      children: [
                        TextSpan(
                          text: _isRegister ? 'Sudah punya akun? ' : 'Belum punya akun? ',
                        ),
                        TextSpan(
                          text: _isRegister ? 'Masuk di sini' : 'Daftar sekarang',
                          style: TextStyle(
                            color: isDark ? AppColors.accentDark : AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required bool active,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? (isDark ? AppColors.surfaceDark : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active
                ? (isDark ? AppColors.inkDark : AppColors.inkLight)
                : (isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(bool isDark, String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.inkDark : AppColors.inkLight,
      ),
    );
  }

  Widget _buildBrandHeader(bool isDark) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: const LinearGradient(
              colors: [Color(0xFFE8542F), Color(0xFFFF6B42)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE8542F).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'C',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CALI TRACKER',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isDark ? AppColors.inkDark : AppColors.inkLight,
              ),
            ),
            Text(
              'Home Workout & Fitness',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final emailVal = _email.text.trim();
    final passVal = _pass.text;

    if (_isRegister) {
      final nameVal = _name.text.trim();
      if (nameVal.isEmpty || emailVal.isEmpty) {
        setState(() => _error = 'Harap isi nama dan email');
        return;
      }
      if (passVal.length < 6) {
        setState(() => _error = 'Password minimal 6 karakter');
        return;
      }
      setState(() => _loading = true);
      final ok = await _auth.register(name: nameVal, email: emailVal, password: passVal);
      if (!mounted) return;
      setState(() => _loading = false);
      if (ok) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
        widget.onSuccess();
      } else {
        setState(() => _error = 'Email sudah terdaftar. Silakan pilih tab Masuk.');
      }
    } else {
      if (emailVal.isEmpty || passVal.isEmpty) {
        setState(() => _error = 'Harap isi email dan password');
        return;
      }
      setState(() => _loading = true);
      final ok = await _auth.login(email: emailVal, password: passVal);
      if (!mounted) return;
      setState(() => _loading = false);
      if (ok) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
        widget.onSuccess();
      } else {
        setState(() => _error = 'Email atau password salah');
      }
    }
  }
}
