import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';
import 'admin_users.dart';
import 'home_screen.dart';
import 'media_admin_screen.dart';
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
    final bool isController = s.user?.id == 'ctrl';
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final screens = <Widget>[
      HomeScreen(onOpenProducts: () => setState(() => _idx = 1)),
      const ProductsScreen(),
      const WalletScreen(),
      isController
          ? const AdminCodeView()
          : (isAdmin ? const CreateAccountPage() : const FavoritesScreen()),
      isAdmin ? const MediaAdminScreen() : const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _idx, children: screens),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, MediaQuery.of(context).padding.bottom + 14),
        child: LayoutBuilder(
          builder: (context, cons) {
            final icons = <IconData>[
              Icons.home_rounded,
              Icons.grid_view_rounded,
              Icons.account_balance_wallet_rounded,
              isController
                  ? Icons.code_rounded
                  : (isAdmin
                      ? Icons.person_add_alt_1_rounded
                      : Icons.favorite_rounded),
              isAdmin ? Icons.campaign_rounded : Icons.person_rounded,
            ];
            final labels = <String>[
              s.isArabic ? 'الرئيسية' : 'Home',
              s.isArabic ? 'المنتجات' : 'Products',
              s.isArabic
                  ? (isAdmin ? 'النقاط والرصيد' : 'المحفظة')
                  : (isAdmin ? 'Points' : 'Wallet'),
              s.isArabic
                  ? (isController
                      ? 'الإدارة'
                      : (isAdmin ? 'إنشاء حساب' : 'المفضلة'))
                  : (isController
                      ? 'Admin'
                      : (isAdmin ? 'Create' : 'Favorites')),
              s.isArabic
                  ? (isAdmin ? 'إدارة الإعلام' : 'ملف شخصي')
                  : (isAdmin ? 'Media' : 'Profile'),
            ];
            final slot = cons.maxWidth / 5;
            return SizedBox(
              height: 90,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ✅ الشريط (الحبة)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF1E1E28) : Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(dark ? 90 : 28),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: List.generate(
                          5,
                          (i) => Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _idx = i),
                              borderRadius: BorderRadius.circular(32),
                              child: Tooltip(
                                message: labels[i],
                                child: Icon(icons[i],
                                    size: 22,
                                    color: _idx == i
                                        ? Colors.transparent
                                        : (dark
                                            ? Colors.grey.shade300
                                            : const Color(0xFF43434E))),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ✅ الدائرة المتوهجة المنزلاقة (تطفو فوق الشريط)
                  AnimatedPositionedDirectional(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    start: slot * _idx + (slot - 56) / 2,
                    bottom: 34,
                    width: 56,
                    height: 56,
                    child: Tooltip(
                      message: labels[_idx],
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: <Color>[
                              Color(0xFFFF8C00),
                              Color(0xFFE8446B),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE8446B)
                                  .withAlpha(dark ? 120 : 90),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: AppColors.orange.withAlpha(60),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(icons[_idx],
                            size: 24, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
