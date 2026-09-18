import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';
import 'home_screen.dart';
import 'products_screen.dart';
import 'profile_screen.dart';
import 'simple_screens.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final bool isAdmin = s.isAdmin || s.isImageAdmin;

    final screens = <Widget>[
      HomeScreen(onOpenProducts: () => setState(() => _idx = 1)),
      const ProductsScreen(),
      const WalletScreen(),
      const FavoritesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: s.isArabic ? 'الرئيسية' : 'Home'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.grid_view_rounded),
              label: s.isArabic ? 'المنتجات' : 'Products'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_wallet_rounded),
              label: s.isArabic ? 'المحفظة' : 'Wallet'),
          BottomNavigationBarItem(
              icon: Icon(isAdmin ? Icons.code_rounded : Icons.favorite_rounded),
              label: s.isArabic
                  ? (isAdmin ? 'الإدارة' : 'المفضلة')
                  : (isAdmin ? 'Admin' : 'Favorites')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: s.isArabic ? 'ملف شخصي' : 'Profile'),
        ],
      ),
    );
  }
}
