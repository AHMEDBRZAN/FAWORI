import 'package:flutter/material.dart';
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
  void _go(int i) => setState(() => _index = i);

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
