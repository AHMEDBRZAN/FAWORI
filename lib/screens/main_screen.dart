import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/locked_dialog.dart';
import '../widgets/bottom_nav.dart';
import 'home_screen.dart';
import 'products_screen.dart';
import 'settings_screen.dart';
import 'simple_screens.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  Future<void> _go(int i) async {
    if (i == _index) return;
    final s = context.read<AppSettings>();
    if (s.isGuest && (i == 2 || i == 3)) {
      showLockedDialog(context, s);
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            HomeScreen(onOpenProducts: () => _go(1)),
            const ProductsScreen(),
            const WalletScreen(),
            const FavoritesScreen(),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: BottomNav(index: _index, onTap: _go),
      );
}
