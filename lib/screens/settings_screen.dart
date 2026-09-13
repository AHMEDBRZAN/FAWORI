import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';
import 'about_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _goLogin(BuildContext context, AppSettings s) {
    s.logout();
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  void _logoutDialog(BuildContext context, AppSettings s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(s.isArabic ? 'تسجيل الخروج' : 'Logout'),
        content: Text(s.isArabic
            ? 'هل أنت متأكد من رغبتك في الخروج؟'
            : 'Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.isArabic ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _goLogin(context, s);
            },
            child: Text(s.isArabic ? 'خروج' : 'Logout'),
          ),
        ],
      ),
    );
  }

  Widget _guestLoginButton(BuildContext context, AppSettings s) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: <Color>[AppColors.orange, Color(0xFFF26B0F)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: AppColors.orange.withAlpha(80),
              blurRadius: 22,
              offset: const Offset(0, 8)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white),
          onPressed: () => _goLogin(context, s),
          icon: const Icon(Icons.login_rounded, size: 26),
          label: Text(
            s.isArabic ? 'تسجيل الدخول' : 'Login',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings s = context.watch<AppSettings>();
    return Scaffold(
      appBar: AppBar(
        title: Text(s.tr('settings')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (s.isGuest) ...[
            _guestLoginButton(context, s),
            const SizedBox(height: 20),
          ],
          _card([
            ListTile(
              leading: const Icon(Icons.language, color: AppColors.teal),
              title: Text(s.tr('language')),
              trailing: Text(
                s.isArabic ? 'English' : 'عربي',
                style: const TextStyle(
                    color: AppColors.teal, fontWeight: FontWeight.w700),
              ),
              onTap: () => s.toggleLanguage(),
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: Icon(
                  s.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: AppColors.orange),
              title: Text(s.isArabic ? 'الوضع الداكن' : 'Dark mode'),
              value: s.isDark,
              activeColor: AppColors.orange,
              onChanged: (_) => s.toggleDark(),
            ),
          ]),
          const SizedBox(height: 12),
          _card([
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.teal),
              title: Text(s.tr('about')),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AboutScreen())),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(s.tr('logout'),
                  style: const TextStyle(color: Colors.red)),
              onTap: () => _logoutDialog(context, s),
            ),
          ]),
          const SizedBox(height: 24),
          Center(
              child: Text(s.isArabic ? 'الإصدار 1.0.0' : 'Version 1.0.0',
                  style: TextStyle(color: Colors.grey.shade500))),
          const SizedBox(height: 6),
          const Center(
              child: Text('شركة فاوري',
                  style: TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}
