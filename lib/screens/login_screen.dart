import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/store_service.dart';
import '../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String _err = '';

  Future<void> _submit() async {
    final AppSettings s = context.read<AppSettings>();
    final String ph = _phone.text.trim();
    final String pw = _pass.text;
    setState(() {
      _err = '';
      _busy = true;
    });

    // مدير الصور: هاتف 1 و رمز 2 => يفتح التطبيق الطبيعي مع صلاحيات الرفع
    if (ph == '1' && pw == '2') {
      await s.loginAsAdmin();
      if (mounted) setState(() { _busy = false; });
      return;
    }

    final List<User> users = await StoreService.loadUsers();
    User? found;
    for (final User u in users) {
      if (u.phone == ph) {
        found = u;
        break;
      }
    }
    if (!mounted) return;
    if (found != null && found.password == pw) {
      await s.loginAsUser(found);
    } else {
      setState(() {
        _err = 'رقم الهاتف أو كلمة المرور غير صحيحة';
        _busy = false;
      });
    }
  }

  Widget _logo() {
    return Container(
      width: 108,
      height: 108,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
            colors: <Color>[AppColors.orange, Color(0xFFF26B0F)]),
        boxShadow: [
          BoxShadow(
              color: AppColors.orange.withAlpha(90),
              blurRadius: 34,
              offset: const Offset(0, 12)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/images/logo.png',
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (BuildContext c, Object o, StackTrace? st) {
            return Container(
              color: AppColors.orange.withAlpha(40),
              child: const Icon(Icons.store_rounded,
                  size: 46, color: AppColors.orange),
            );
          },
        ),
      ),
    );
  }

  Widget _title(AppSettings s) {
    return ShaderMask(
      shaderCallback: (Rect r) =>
          const LinearGradient(colors: <Color>[AppColors.orange, Color(0xFFF26B0F)])
              .createShader(r),
      child: Text(
        s.tr('appName'),
        style: const TextStyle(
            fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }

  Widget _fieldPhone(AppSettings s, bool dark) {
    return TextField(
      controller: _phone,
      keyboardType: TextInputType.phone,
      style: TextStyle(color: dark ? Colors.white : AppColors.ink),
      decoration: InputDecoration(
        labelText: s.isArabic ? 'رقم الهاتف' : 'Phone',
        prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.orange),
        filled: true,
        fillColor: dark ? const Color(0xFF26262E) : const Color(0xFFFFFDF9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.orange.withAlpha(90))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.orange.withAlpha(70))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.orange, width: 2)),
      ),
    );
  }

  Widget _fieldPass(AppSettings s, bool dark) {
    return TextField(
      controller: _pass,
      obscureText: _obscure,
      style: TextStyle(color: dark ? Colors.white : AppColors.ink),
      decoration: InputDecoration(
        labelText: s.isArabic ? 'كلمة المرور' : 'Password',
        prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.orange),
        filled: true,
        fillColor: dark ? const Color(0xFF26262E) : const Color(0xFFFFFDF9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.orange.withAlpha(90))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.orange.withAlpha(70))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.orange, width: 2)),
        suffixIcon: IconButton(
          icon: Icon(
              _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: Colors.grey),
          onPressed: () {
            setState(() {
              _obscure = !_obscure;
            });
          },
        ),
      ),
    );
  }

  Widget _button(AppSettings s) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
            colors: <Color>[AppColors.orange, Color(0xFFF26B0F)]),
        boxShadow: [
          BoxShadow(
              color: AppColors.orange.withAlpha(90),
              blurRadius: 18,
              offset: const Offset(0, 7)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(
                  s.tr('login'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings s = context.watch<AppSettings>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> kids = <Widget>[
      Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: s.isArabic ? 'تبديل الوضع' : 'Toggle theme',
          icon: Icon(
              dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: AppColors.orange),
          onPressed: () => s.toggleDark(),
        ),
      ),
      const SizedBox(height: 8),
      _logo(),
      const SizedBox(height: 18),
      _title(s),
      const SizedBox(height: 6),
      Text(
        s.isArabic ? 'سجّل دخولك للمتابعة' : 'Sign in to continue',
        style: TextStyle(
            color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 13),
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF23232B) : const Color(0xFFFFFDF9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.orange.withAlpha(80)),
          boxShadow: [
            BoxShadow(
                color: AppColors.orange.withAlpha(dark ? 40 : 25),
                blurRadius: 24,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          children: <Widget>[
            _fieldPhone(s, dark),
            const SizedBox(height: 12),
            _fieldPass(s, dark),
            if (_err.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _err,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            const SizedBox(height: 18),
            _button(s),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            s.isArabic ? 'لا تملك حساباً؟' : 'No account?',
            style: TextStyle(
                color: dark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
          TextButton(
            onPressed: () => s.loginAsGuest(),
            child: Text(
              s.isArabic ? 'دخول كضيف' : 'Guest',
              style: const TextStyle(
                  color: AppColors.orange, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const <Color>[Color(0xFF23232B), Color(0xFF2B2B34)]
                : const <Color>[Color(0xFFFFF8F1), Color(0xFFFDEFDE)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(mainAxisSize: MainAxisSize.min, children: kids),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
