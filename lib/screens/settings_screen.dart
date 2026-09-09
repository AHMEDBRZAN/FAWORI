import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';
import '../widgets/pressable.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final canPop = Navigator.of(context).canPop();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final card = BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.border(context)),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                icon: Icon(rtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(s.tr('settings'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
                title: Text(s.isDark
                    ? s.tr('darkMode')
                    : (s.isArabic ? 'الوضع الفاتح' : 'Light mode')),
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
    );
  }

  void _logoutDialog(BuildContext context, AppSettings s) => showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    AppColors.red.withAlpha(170),
                    AppColors.orange.withAlpha(130),
                  ]),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.red.withAlpha(50),
                        blurRadius: 20,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(s.tr('confirmLogout'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(
                  child: Pressable(
                    onTap: () {
                      Navigator.of(context)
                          .popUntil((route) => route.isFirst);
                      s.logout();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Color(0xFFE5484D),
                          AppColors.red,
                        ]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(s.tr('yes'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Pressable(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border:
                            Border.all(color: AppTheme.border(context)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(s.tr('no'),
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      );
}
