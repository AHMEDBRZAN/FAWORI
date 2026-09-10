import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _pic;

  @override
  void initState() {
    super.initState();
    _loadPic();
  }

  Future<void> _loadPic() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _pic = p.getString('profile_pic'));
  }

  Future<void> _pick() async {
    final f = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 50, maxWidth: 600, maxHeight: 600);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    final b64 = base64Encode(bytes);
    final p = await SharedPreferences.getInstance();
    await p.setString('profile_pic', b64);
    if (mounted) setState(() => _pic = b64);
  }

  /// تنسيق الأرقام بفواصل: 14000 => 14,000
  String _fmt(num n) {
    final s = n.toStringAsFixed(0);
    final out = StringBuffer();
    var c = 0;
    for (var i = s.length - 1; i >= 0; i--) {
      out.write(s[i]);
      c++;
      if (c % 3 == 0 && i != 0) out.write(',');
    }
    return out.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    if (s.user == null) return const SettingsScreen();
    final u = s.user!;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(s.isArabic ? 'ملف الشخصي' : 'Profile',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.orange, width: 3),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.orange.withAlpha(60), blurRadius: 24)
                      ],
                    ),
                    child: ClipOval(
                      child: _pic != null
                          ? Image.memory(base64Decode(_pic!), fit: BoxFit.cover)
                          : Container(
                              color: AppColors.orange.withAlpha(30),
                              child: const Icon(Icons.person_rounded,
                                  size: 60, color: AppColors.orange),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: InkWell(
                      onTap: _pick,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.photo_camera_rounded,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(u.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(u.phone,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.teal.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                    u.role == 'agent'
                        ? (s.isArabic ? 'وكيل معتمد' : 'Agent')
                        : u.role == 'tech'
                            ? (s.isArabic ? 'صباغ' : 'Painter')
                            : (s.isArabic ? 'عميل' : 'Customer'),
                    style: const TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: _statCard(
                  icon: Icons.stars_rounded,
                  value: _fmt(u.points),
                  label: s.isArabic ? 'نقطة' : 'points',
                  colors: const [Color(0xFFF26B0F), AppColors.orange],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  icon: Icons.savings_rounded,
                  value: _fmt(u.stored),
                  label: s.isArabic ? 'رصيد مخزن' : 'stored',
                  colors: const [Color(0xFF2BAE9E), AppColors.teal],
                ),
              ),
            ]),
            const SizedBox(height: 24),
            InkWell(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: Row(children: [
                  const Icon(Icons.settings_rounded, color: AppColors.orange),
                  const SizedBox(width: 12),
                  Text(s.isArabic ? 'الإعدادات' : 'Settings',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  const Icon(Icons.chevron_left_rounded, color: Colors.grey),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
          {required IconData icon,
          required String value,
          required String label,
          required List<Color> colors}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: colors.first.withAlpha(60),
                blurRadius: 18,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );
}
