import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final card = BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.border(context)),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(s.tr('settings'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Container(
              decoration: card,
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppColors.teal),
                  title: Text(s.tr('language')),
                  trailing: TextButton(
                    onPressed: s.toggleLanguage,
                    child: Text(s.isArabic ? 'English' : 'العربية',
                        style: const TextStyle(
                            color: AppColors.teal, fontWeight: FontWeight.w700)),
                  ),
                ),
                Divider(height: 1, color: AppTheme.border(context)),
                ListTile(
                  leading: Icon(
                      s.isDark
                          ? Icons.nightlight_round
                          : Icons.wb_sunny_rounded,
                      color: AppColors.orange),
                  title: Text(s.isDark ? s.tr('darkMode') : (s.isArabic ? 'الوضع الفاتح' : 'Light mode')),
                  trailing: Switch(value: s.isDark, onChanged: (_) => s.toggleDark()),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: card,
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.teal),
                  title: Text(s.tr('about')),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AboutScreen())),
                ),
                Divider(height: 1, color: AppTheme.border(context)),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.red),
                  title: Text(s.tr('logout'),
                      style: const TextStyle(color: AppColors.red)),
                  onTap: () => _logoutDialog(context, s),
                ),
              ]),
            ),
            const SizedBox(height: 30),
            Center(
                child: Text(s.tr('version'),
                    style: TextStyle(color: Colors.grey.shade500))),
            const SizedBox(height: 8),
            Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset('assets/images/logo.png',
                      width: 30, height: 30, fit: BoxFit.cover),
                ),
                const SizedBox(width: 8),
                Text(s.tr('appName'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _logoutDialog(BuildContext context, AppSettings s) => showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 55),
                padding: const EdgeInsets.fromLTRB(20, 70, 20, 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.tr('confirmLogout'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF26B0F),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              s.logout();
                            },
                            child: Text(s.tr('yes')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(s.tr('no')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF26B0F),
                ),
                child: const Icon(Icons.question_mark_rounded,
                    size: 70, color: Colors.white),
              ),
            ],
          ),
        ),
      );
}
