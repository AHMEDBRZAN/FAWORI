import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/app_settings.dart';
import 'core/favorites.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.restoreSession();
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
      title: 'Fawori',
      debugShowCheckedModeBanner: false,
      theme: s.isDark ? AppTheme.dark() : AppTheme.light(),
      locale: s.isArabic ? const Locale('ar') : const Locale('en'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: s.isLoggedIn ? const MainScreen() : const LoginScreen(),
    );
  }
}
