import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_settings.dart';
import 'core/favorites.dart';
import 'core/messenger.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => AppSettings()),
    ChangeNotifierProvider(create: (_) => Favorites()),
  ], child: const FaworiApp()));
}

class FaworiApp extends StatefulWidget {
  const FaworiApp({super.key});
  @override
  State<FaworiApp> createState() => _FaworiAppState();
}

class _FaworiAppState extends State<FaworiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 🔄 عند عودة التطبيق إلى المقدمة ← فحص فوري + إعادة Timer
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final s = context.read<AppSettings>();
      s.forceRefresh();
    }
  }

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
      await context
          .read<AppSettings>()
          .restoreSession()
          .timeout(const Duration(seconds: 6));
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 1200));
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: AppColors.orange, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.teal.withAlpha(60), blurRadius: 40),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset('assets/images/logo.webp',
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
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900)),
                          ),
                        )),
              ),
            ),
            const SizedBox(height: 22),
            ShaderMask(
              shaderCallback: (Rect r) => const LinearGradient(
                      colors: <Color>[AppColors.teal, AppColors.orange])
                  .createShader(r),
              child: const Text('شركة فاورِي',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
            const SizedBox(height: 26),
            const CircularProgressIndicator(
                color: AppColors.teal, backgroundColor: Color(0x33E8A33C)),
          ],
        ),
      ),
    );
  }
}
