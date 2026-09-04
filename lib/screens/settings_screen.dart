import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
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
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.nightlight_round, color: AppColors.orange),
                  title: Text(s.tr('darkMode')),
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
                  onTap: () => _about(context, s),
                ),
                const Divider(height: 1),
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
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                          colors: [AppColors.orange, AppColors.teal])
                      .createShader(r),
                  child:
                      const Icon(Icons.waves_rounded, size: 26, color: Colors.white),
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

  void _about(BuildContext context, AppSettings s) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(s.tr('about')),
          content: Text(s.tr('aboutText')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text(s.tr('ok')))
          ],
        ),
      );

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
