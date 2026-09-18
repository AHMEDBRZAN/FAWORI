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

  // ✅ استعادة الجلسة قبل runApp — بدون أي شاشة مقدمة
  try {
    await settings.restoreSession().timeout(const Duration(seconds: 3));
  } catch (_) {}

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
      // ✅ دخول مباشر: مسجّل ← التطبيق | غير مسجّل ← تسجيل الدخول
      home: s.isLoggedIn ? const MainScreen() : const LoginScreen(),
      builder: (context, child) => Directionality(
        textDirection: s.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
