import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_settings.dart';
import 'core/favorites.dart';
import 'core/messenger.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

/// ✅ مفتاح عام للوصول لـ Supabase من أي مكان في التطبيق
final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ تهيئة Supabase قبل أي شيء آخر
  await Supabase.initialize(
    // ⚠️ ضع رابط مشروعك من صفحة Data API (بدون /rest/v1/)
    url: 'https://nnaiffzxrbguutxeawot.supabase.co',
    // ⚠️ ضع مفتاح anon (الذي يبدأ بـ eyJ...) من صفحة API Keys
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5uYWlmZnp4cmJndXV0eGVhd290Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA2MDQyMjUsImV4cCI6MjEwNjE4MDIyNX0.6A3LNXFi2rr7mkcaG5EYLX2fSfbqUujxP9wRVMfCSF4',
  );

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppSettings()),
      ChangeNotifierProvider(create: (_) => Favorites()),
    ],
    child: const FaworiApp(),
  ));
}
