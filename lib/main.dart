import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_settings.dart';
import 'core/favorites.dart';
import 'core/messenger.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ قراءة الثيم المحفوظ قبل أول إطار + تلوين خلفية الصفحة بنفس اللون
  final p = await SharedPreferences.getInstance();
  final dark = p.getBool('isDark') ?? false;
  final arabic = p.getBool('isArabic') ?? true;
  try {
    html.document.body?.style.backgroundColor =
        dark ? '#141419' : '#EFF2F7';
  } catch (_) {}

  final settings = AppSettings()..applyInitial(dark: dark, arabic: arabic);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider(create: (_) => Favorites()),
    ],
    child: const FaworiApp(),
  ));
}

class FaworiApp extends StatelessWidget {
  const FaworiApp({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return MaterialApp(
      title: 'FAWORI',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      themeMode: s.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const SplashGate(),
      builder: (context, child) => Directionality(
        textDirection: s.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      // ✅ مهلة قصوى 3 ثوانٍ فقط
      await context
          .read<AppSettings>()
          .restoreSession()
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    if (!_ready) return const SplashView();
    return s.isLoggedIn ? const MainScreen() : const LoginScreen();
  }
}

/// ✅ Splash موحّد اللون حسب ثيم التطبيق — خفيف وسريع — صورة webp
class SplashView extends StatelessWidget {
  const SplashView({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final bool dark = s.isDark;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF141419) : const Color(0xFFEFF2F7),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.orange, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                // ✅ الشعار بصيغة webp (أصغر وأسرع تحميلاً)
                child: Image.asset(
                  'assets/images/logo.webp',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (c, o, st) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: <Color>[
                        Color(0xFFFFA500),
                        Color(0xFFFF8C00)
                      ]),
                    ),
                    child: const Center(
                      child: Text('FAWORI',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'شركة فاورِي',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: dark ? AppColors.teal : AppColors.orange,
              ),
            ),
            const SizedBox(height: 22),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: AppColors.teal),
            ),
          ],
        ),
      ),
    );
  }
}
