import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/store_service.dart';
import '../core/theme.dart';
import '../widgets/pressable.dart';
import 'image_admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String _err = '';

  Future<void> _submit() async {
    final s = context.read<AppSettings>();
    final ph = _phone.text.trim();
    final pw = _pass.text;
    setState(() { _err = ''; _busy = true; });

    // 🔐 الدخول الخاص بمدير الصور
    if (ph == 'احمد' && pw == '1997') {
      s.enterImageAdmin();
      if (mounted) {
        setState(() => _busy = false);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ImageAdminScreen()));
      }
      return;
    }

    final users = await StoreService.loadUsers();
    User? found;
    for (final u in users) {
      if (u.phone == ph) { found = u; break; }
    }
    if (!mounted) return;
    if (found != null && found.password == pw) {
      await s.loginAsUser(found);
    } else {
      setState(() { _err = 'رقم الهاتف أو كلمة المرور غير صحيحة'; _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(s.tr('login'),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                      labelText: s.isArabic ? 'رقم الهاتف' : 'Phone',
                      prefixIcon: const Icon(Icons.phone_rounded)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pass,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                      labelText: s.isArabic ? 'كلمة المرور' : 'Password',
                      prefixIcon: const Icon(Icons.lock_rounded),
                      suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          onPressed: () => setState(() => _obscure = !_obscure))),
                ),
                if (_err.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(_err, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.black),
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(s.tr('login'),
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(s.isArabic ? 'لا تملك حساباً؟' : 'No account?',
                      style: TextStyle(color: Colors.grey.shade400)),
                  TextButton(
                      onPressed: () => s.loginAsGuest(),
                      child: Text(s.isArabic ? 'دخول كضيف' : 'Guest',
                          style: const TextStyle(color: AppColors.teal))),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
