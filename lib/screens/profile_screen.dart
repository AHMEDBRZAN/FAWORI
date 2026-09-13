import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_settings.dart';
import '../core/store_service.dart';
import '../core/theme.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _localB64;
  String? _repoPath;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = context.read<AppSettings>().user?.id ?? '';
    if (uid.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    final m = await ImagesService.loadImages();
    final profiles = Map<String, dynamic>.from(m['profiles'] ?? {});
    if (mounted) {
      setState(() {
        _localB64 = p.getString('profile_pic_$uid');
        _repoPath = profiles[uid] as String?;
      });
    }
  }

  Future<void> _pick() async {
    final s = context.read<AppSettings>();
    final uid = s.user?.id ?? '';
    if (uid.isEmpty) return;
    final f = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 70, maxWidth: 600);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    setState(() => _busy = true);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('profile_pic_$uid', base64Encode(bytes));
      final path = 'assets/profiles/$uid.png';
      await ImagesService.putBytes(path, bytes, kUploadToken, 'profile $uid');
      await ImagesService.setMapping('profiles', uid, path, kUploadToken);
      if (mounted) {
        setState(() {
          _localB64 = base64Encode(bytes);
          _repoPath = path;
          _busy = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('✅ تم رفع صورتك')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل الرفع: $e')));
      }
    }
  }

  // 🎯 وضع الضيف: زر تسجيل دخول كبير متدرج
  Widget _guestView(AppSettings s) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? const <Color>[Color(0xFF23232B), Color(0xFF2B2B34)]
                : const <Color>[Color(0xFFFFF8F1), Color(0xFFFDEFDE)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: <Color>[AppColors.orange, Color(0xFFF26B0F)]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.orange.withAlpha(80),
                          blurRadius: 30,
                          offset: const Offset(0, 10)),
                    ],
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      size: 60, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  s.isArabic ? 'أنت تتصفح كضيف' : 'Browsing as guest',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  s.isArabic
                      ? 'سجّل دخولك لعرض نقاطك ورصيدك وفواتيرك'
                      : 'Sign in to view your points, balance & invoices',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: <Color>[AppColors.orange, Color(0xFFF26B0F)]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.orange.withAlpha(90),
                        blurRadius: 20,
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
                    onPressed: () => s.logout(),
                    icon: const Icon(Icons.login_rounded, size: 24),
                    label: Text(
                      s.isArabic ? 'تسجيل الدخول' : 'Sign in',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    side: const BorderSide(color: AppColors.teal, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {},
                child: Text(
                  s.isArabic ? 'المتابعة كضيف' : 'Continue as guest',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _userView(AppSettings s, User u) {
    return Scaffold(
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? const <Color>[Color(0xFF23232B), Color(0xFF2B2B34)]
                      : const <Color>[Color(0xFFFFF8F1), Color(0xFFFDEFDE)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(s.isArabic ? 'ملف الشخصي' : 'Profile',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 24),
                    Center(
                      child: Stack(clipBehavior: Clip.none, children: [
                        Container(
                          width: 116,
                          height: 116,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: AppColors.orange, width: 3)),
                          child: ClipOval(
                            child: _repoPath != null
                                ? Image.network(
                                    ImagesService.remoteUrl(_repoPath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, o, st) => _fallback())
                                : (_localB64 != null
                                    ? Image.memory(base64Decode(_localB64!),
                                        fit: BoxFit.cover)
                                    : _fallback()),
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
                                  border: Border.all(
                                      color: Colors.white, width: 2)),
                              child: const Icon(Icons.photo_camera_rounded,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    Center(
                        child: Text(u.name,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800))),
                    const SizedBox(height: 4),
                    Center(
                        child: Text(u.phone,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13))),
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(
                          child: _stat(s.isArabic ? 'نقطة' : 'points', u.points,
                              AppColors.orange)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _stat(s.isArabic ? 'رصيد مخزن' : 'stored',
                              u.stored, AppColors.teal)),
                    ]),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border(context))),
                        child: Row(children: [
                          const Icon(Icons.settings_rounded,
                              color: AppColors.orange),
                          const SizedBox(width: 12),
                          Text(s.isArabic ? 'الإعدادات' : 'Settings',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          const Icon(Icons.chevron_left_rounded,
                              color: Colors.grey),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _fallback() => Container(
      color: AppColors.orange.withAlpha(30),
      child: const Icon(Icons.person_rounded, size: 60, color: AppColors.orange));

  Widget _stat(String label, int value, Color c) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c, c.withAlpha(200)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18)),
        child: Column(children: [
          Text('$value',
              style: const TextStyle(
                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    if (s.isGuest || s.user == null) return _guestView(s);
    return _userView(s, s.user!);
  }
}
