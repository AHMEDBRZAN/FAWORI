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

  // ✅ قراءة الثيم المحفوظ قبل أول إطار (يمنع وميض اللون)
  final p = await SharedPreferences.getInstance();
  final dark = p.getBool('isDark') ?? false;
  final arabic = p.getBool('isArabic') ?? true;
  try {
    html.document.body?.style.backgroundColor =
        dark ? '#141419' : '#EFF2F7';
  } catch (_) {}

  final settings = AppSettings()..applyInitial(dark: dark, arabic: arabic);

  // ✅ runApp فوراً — بدون انتظار
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
      home: const _Gate(),
      builder: (context, child) => Directionality(
        textDirection: s.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// ✅ بوابة صامتة: خلفية بلون الثيم + مؤشر صغير فقط أثناء استعادة الجلسة
class _Gate extends StatefulWidget {
  const _Gate();
  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await context
          .read<AppSettings>()
          .restoreSession()
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    if (_ready) {
      return s.isLoggedIn ? const MainScreen() : const LoginScreen();
    }
    return Scaffold(
      backgroundColor:
          s.isDark ? const Color(0xFF141419) : const Color(0xFFEFF2F7),
      body: const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
              strokeWidth: 3, color: AppColors.teal),
        ),
      ),
    );
  }
}
