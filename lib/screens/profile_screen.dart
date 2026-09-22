import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/orders_service.dart';
import '../core/theme.dart';
import 'about_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _roleAr(String r) {
    if (r == 'agent') return 'وكيل';
    if (r == 'tech') return 'صباغ';
    if (r == 'admin') return 'مدير';
    return 'عميل';
  }

  void _logout(BuildContext context) {
    final s = context.read<AppSettings>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  s.isArabic ? 'تسجيل الخروج' : 'Logout',
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        content: Text(
            s.isArabic
                ? 'هل تريد تسجيل الخروج من حساب ${s.user?.name ?? ''}؟'
                : 'Do you want to logout from ${s.user?.name ?? ''}?',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.isArabic ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              s.logout();
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false);
            },
            child: Text(s.isArabic ? 'خروج' : 'Logout'),
          ),
        ],
      ),
    );
  }

  Widget _settingRow(BuildContext context,
      {required IconData icon,
      required String label,
      Color? iconColor,
      Widget? trailing,
      VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.orange, size: 22),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15))),
            if (trailing != null)
              trailing
            else
              Icon(Icons.chevron_left_rounded,
                  color: Colors.grey.shade500, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, int value, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: <Color>[c, c.withAlpha(200)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(fmtThousands(value),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withAlpha(230),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final u = s.user;
    final bool isGuest = u == null || u.role == 'guest';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(s.isArabic ? 'ملف الشخصي' : 'Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 12),
          // ===== الصورة الشخصية =====
          Center(
            child: Stack(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withAlpha(25),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.orange, width: 2),
                  ),
                  child: Icon(Icons.person_rounded,
                      size: 56, color: AppColors.orange),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.photo_camera_rounded,
                        size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              u?.name ?? (s.isArabic ? 'ضيف' : 'Guest'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              isGuest
                  ? (s.isArabic ? 'حساب ضيف' : 'Guest account')
                  : '${s.isArabic ? _roleAr(u!.role) : u.role}${u!.phone.isNotEmpty ? ' • ${u.phone}' : ''}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          // ===== النقاط والرصيد =====
          Row(
            children: [
              Expanded(
                  child: _stat(
                      s.isArabic ? 'نقطة' : 'points', s.points, AppColors.orange)),
              const SizedBox(width: 12),
              Expanded(
                  child: _stat(s.isArabic ? 'رصيد مخزن' : 'stored', s.stored,
                      AppColors.teal)),
            ],
          ),
          const SizedBox(height: 20),
          // ===== زر دخول للضيف =====
          if (isGuest) ...[
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: <Color>[AppColors.orange, Color(0xFFF26B0F)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen())),
                  child: Text(
                      s.isArabic ? 'تسجيل الدخول' : 'Login',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          // ===== الإعدادات مدمجة هنا (بدل زر الإعدادات) =====
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.orange.withAlpha(40)),
            ),
            child: Column(
              children: [
                _settingRow(
                  context,
                  icon: Icons.language_rounded,
                  iconColor: AppColors.teal,
                  label: s.isArabic ? 'اللغة' : 'Language',
                  trailing: Text(
                    s.isArabic ? 'English' : 'عربي',
                    style: const TextStyle(
                        color: AppColors.teal, fontWeight: FontWeight.w800),
                  ),
                  onTap: () => s.toggleLanguage(),
                ),
                Divider(height: 1, color: Colors.grey.withAlpha(40)),
                _settingRow(
                  context,
                  icon: s.isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  label: s.isArabic ? 'الوضع الداكن' : 'Dark mode',
                  trailing: Switch(
                    value: s.isDark,
                    onChanged: (_) => s.toggleDark(),
                  ),
                ),
                Divider(height: 1, color: Colors.grey.withAlpha(40)),
                _settingRow(
                  context,
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.teal,
                  label: s.isArabic ? 'حول التطبيق' : 'About',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AboutScreen())),
                ),
                Divider(height: 1, color: Colors.grey.withAlpha(40)),
                _settingRow(
                  context,
                  icon: Icons.logout_rounded,
                  iconColor: Colors.red,
                  label: s.isArabic ? 'تسجيل الخروج' : 'Logout',
                  trailing: const SizedBox.shrink(),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              s.isArabic ? 'الإصدار 1.0.0' : 'Version 1.0.0',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              s.isArabic ? 'شركة فاوري' : 'FAWORI Co.',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
