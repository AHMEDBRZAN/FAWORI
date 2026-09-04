import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final card = BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('الإعدادات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Container(
              decoration: card,
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppColors.teal),
                  title: const Text('اللغة'),
                  trailing: TextButton(
                    onPressed: settings.toggleLanguage,
                    child: Text(settings.isArabic ? 'English' : 'العربية',
                        style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700)),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.nightlight_round, color: AppColors.orange),
                  title: const Text('الوضع الداكن'),
                  trailing: Switch(value: settings.isDark, onChanged: (_) => settings.toggleDark()),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: card,
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.teal),
                  title: const Text('حول التطبيق'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => _about(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.red),
                  title: const Text('تسجيل خروج', style: TextStyle(color: AppColors.red)),
                  onTap: () => _logout(context),
                ),
              ]),
            ),
            const SizedBox(height: 30),
            Center(child: Text('الإصدار 1.0.0', style: TextStyle(color: Colors.grey.shade500))),
            const SizedBox(height: 8),
            Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                          colors: [AppColors.orange, AppColors.teal]).createShader(r),
                  child: const Icon(Icons.waves_rounded, size: 26, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Text('شركة فاوري', style: TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _about(BuildContext context) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('حول التطبيق'),
          content: const Text('تطبيق شركة فاوري لعرض المنتجات والهدايا والوكلاء المعتمدين.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
        ),
      );

  void _logout(BuildContext context) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('خروج', style: TextStyle(color: AppColors.red))),
          ],
        ),
      );
}
