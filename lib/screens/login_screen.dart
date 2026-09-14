import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/store_service.dart';
import '../core/theme.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _err;

  void _go() {
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()), (r) => false);
  }

  Future<void> _login() async {
    if (_busy || !mounted) return;
    final settings = context.read<AppSettings>();
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      final ph = _phone.text.trim();
      final pw = _pass.text.trim();
      if (ph.isEmpty || pw.isEmpty) {
        setState(() {
          _busy = false;
          _err = settings.isArabic ? 'أدخل الهاتف وكلمة المرور' : 'Enter phone & password';
        });
        return;
      }
      if (ph == '1' && pw == '2') {
        await settings.loginAsAdmin();
        _go();
        return;
      }
      final users = await StoreService.loadUsers();
      User? found;
      for (final u in users) {
        if (u.phone == ph) {
          found = u;
          break;
        }
      }
      if (found == null || found.password != pw) {
        setState(() {
          _busy = false;
          _err = settings.isArabic ? 'بيانات الدخول غير صحيحة' : 'Invalid credentials';
        });
        return;
      }
      try {
        await settings.loginAsUser(found);
      } catch (_) {
        settings.syncUser(found);
      }
      _go();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _err = settings.isArabic ? 'تعذر الدخول: $e' : 'Login failed: $e';
        });
      }
    }
  }

  Future<void> _guest() async {
    if (_busy || !mounted) return;
    final settings = context.read<AppSettings>();
    setState(() => _busy = true);
    try {
      await settings.loginAsGuest();
      _go();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _err = settings.isArabic ? 'تعذر دخول الضيف: $e' : 'Guest failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const <Color>[Color(0xFF141419), Color(0xFF1B1B21)]
                : const <Color>[Color(0xFFFFF8F1), Color(0xFFFDEFDE)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.orange, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset('assets/images/logo.webp',
                        fit: BoxFit.cover, gaplessPlayback: true,
                        errorBuilder: (c, o, st) =>
                            const Center(child: Text('FAWORI',
                                style: TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.w900)))),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: ShaderMask(
                  shaderCallback: (Rect r) => const LinearGradient(
                          colors: <Color>[AppColors.teal, AppColors.orange])
                      .createShader(r),
                  child: Text(
                    settings.isArabic ? 'شركة فاوري' : 'FAWORI',
                    style: const TextStyle(fontSize: 24,
                        fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: dark ? Colors.white : AppColors.ink),
                decoration: InputDecoration(
                  hintText: settings.isArabic ? 'رقم الهاتف' : 'Phone',
                  prefixIcon: const Icon(Icons.phone_rounded,
                      color: AppColors.orange),
                  filled: true,
                  fillColor: dark ? const Color(0xFF26262E) : const Color(0xFFFFFDF9),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pass,
                obscureText: true,
                style: TextStyle(color: dark ? Colors.white : AppColors.ink),
                decoration: InputDecoration(
                  hintText: settings.isArabic ? 'كلمة المرور' : 'Password',
                  prefixIcon:
                      const Icon(Icons.lock_outline_rounded, color: AppColors.orange),
                  filled: true,
                  fillColor: dark ? const Color(0xFF26262E) : const Color(0xFFFFFDF9),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 10),
              if (_err != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_err!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center),
                ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: <Color>[AppColors.orange, Color(0xFFF26B0F)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white),
                    onPressed: _busy ? null : _login,
                    child: _busy
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            settings.isArabic ? 'تسجيل الدخول' : 'Login',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal, width: 1.5)),
                  onPressed: _busy ? null : _guest,
                  icon: const Icon(Icons.person_outline_rounded, size: 22),
                  label: Text(
                    settings.isArabic ? 'الدخول كضيف' : 'Continue as guest',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
