import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/store_service.dart';
import '../core/theme.dart';
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
    setState(() {
      _err = '';
      _busy = true;
    });

    if (ph == 'احمد' && pw == '1997') {
      s.enterImageAdmin();
      if (mounted) {
        setState(() {
          _busy = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ImageAdminScreen()),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF141419), Color(0xFF1B1B21)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildContent(s),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppSettings s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLogo(),
        const SizedBox(height: 18),
        _buildTitle(s),
        const SizedBox(height: 6),
        Text(
          s.isArabic ? 'سجّل دخولك للمتابعة' : 'Sign in to continue',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),
        _buildFormCard(s),
        const SizedBox(height: 14),
        _buildGuestLink(s),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.orange, AppColors.teal],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withAlpha(70),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset(
          'assets/images/logo.png',
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _FallbackLogo(),
        ),
      ),
    );
  }

  Widget _buildTitle(AppSettings s) {
    return ShaderMask(
      shaderCallback: (r) {
        return const LinearGradient(
          colors: [AppColors.orange, AppColors.teal],
        ).createShader(r);
      },
      child: Text(
        s.tr('appName'),
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFormCard(AppSettings s) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.orange.withAlpha(60)),
      ),
      child: Column(
        children: [
          _buildPhoneField(s),
          const SizedBox(height: 12),
          _buildPassField(s),
          if (_err.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _err,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
          const SizedBox(height: 18),
          _buildLoginButton(s),
        ],
      ),
    );
  }

  Widget _buildPhoneField(AppSettings s) {
    return TextField(
      controller: _phone,
      keyboardType: TextInputType.phone,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: s.isArabic ? 'رقم الهاتف' : 'Phone',
        prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.orange),
        filled: true,
        fillColor: const Color(0xFF141419),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
    );
  }

  Widget _buildPassField(AppSettings s) {
    return TextField(
      controller: _pass,
      obscureText: _obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: s.isArabic ? 'كلمة المرور' : 'Password',
        prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.teal),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscure = !_obscure;
            });
          },
        ),
        filled: true,
        fillColor: const Color(0xFF141419),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
    );
  }

  Widget _buildLoginButton(AppSettings s) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.orange, AppColors.teal],
        ),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withAlpha(70),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
          ),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  s.tr('login'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildGuestLink(AppSettings s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          s.isArabic ? 'لا تملك حساباً؟' : 'No account?',
          style: TextStyle(color: Colors.grey.shade400),
        ),
        TextButton(
          onPressed: () => s.loginAsGuest(),
          child: Text(
            s.isArabic ? 'دخول كضيف' : 'Guest',
            style: const TextStyle(
              color: AppColors.teal,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      color: AppColors.orange.withAlpha(40),
      child: const Icon(
        Icons.store_rounded,
        size: 44,
        color: AppColors.orange,
      ),
    );
  }
}
