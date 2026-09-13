import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_settings.dart';
import 'core/favorites.dart';
import 'core/theme.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/smart_logo.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettings()),
        ChangeNotifierProvider(create: (_) => Favorites()),
      ],
      child: const FaworiApp(),
    ),
  );
}

class FaworiApp extends StatelessWidget {
  const FaworiApp({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return MaterialApp(
      title: 'FAWORI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: s.isDark ? ThemeMode.dark : ThemeMode.light,
      // 🌍 اتجاه عام لكل النظام: عربي = يمين ، إنكليزي = يسار
      builder: (context, child) {
        return Directionality(
          textDirection: s.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashGate(),
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
    _init();
  }

  Future<void> _init() async {
    final s = context.read<AppSettings>();
    await s.restoreSession();
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    if (!_ready) return const SplashView();
    return s.isLoggedIn ? const MainScreen() : const LoginScreen();
  }
}

class SplashView extends StatelessWidget {
  const SplashView({super.key});
  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const <Color>[Color(0xFF141419), Color(0xFF1B1B21)]
                : const <Color>[Color(0xFFFFF8F1), Color(0xFFFDEFDE)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.orange, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withAlpha(50),
                      blurRadius: 45,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: const SmartLogo(size: 140),
                ),
              ),
              const SizedBox(height: 26),
              ShaderMask(
                shaderCallback: (Rect r) => const LinearGradient(
                        colors: <Color>[AppColors.teal, AppColors.orange])
                    .createShader(r),
                child: const Text(
                  'شركة فاوري',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.orange,
                  backgroundColor: Color(0xFF3A3A40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
