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

/// ✅ رسّام الشريط: حبّة دائرية مع «غرزة» مقعّرة تحتضن الدائرة
class _NotchPainter extends CustomPainter {
  final double cx;
  final bool dark;
  _NotchPainter({required this.cx, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    const barH = 58.0;
    final top = size.height - barH;
    const r = barH / 2;
    const d = 30.0;
    const w = 22.0;
    const s = 4.0;
    final double ccx = cx.clamp(r + w + s, size.width - r - w - s);
    final p = Path()
      ..moveTo(0, top + r)
      ..quadraticBezierTo(0, top, r, top)
      ..lineTo(ccx - w - s, top)
      ..quadraticBezierTo(ccx - w + 2, top + 2, ccx - w + 5, top + d * 0.55)
      ..quadraticBezierTo(ccx - w * 0.45, top + d, ccx, top + d)
      ..quadraticBezierTo(ccx + w * 0.45, top + d, ccx + w - 5, top + d * 0.55)
      ..quadraticBezierTo(ccx + w - 2, top + 2, ccx + w + s, top)
      ..lineTo(size.width - r, top)
      ..quadraticBezierTo(size.width, top, size.width, top + r)
      ..quadraticBezierTo(size.width, top + barH, size.width - r, top + barH)
      ..lineTo(r, top + barH)
      ..quadraticBezierTo(0, top + barH, 0, top + r)
      ..close();
    canvas.drawShadow(p, Colors.black.withAlpha(80), 12, true);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: dark
            ? const <Color>[Color(0xFF23232C), Color(0xFF1B1B22)]
            : const <Color>[Colors.white, Color(0xFFF6F6F9)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, top, size.width, barH));
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant _NotchPainter old) =>
      old.cx != cx || old.dark != dark;
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _idx = 0;
  int _prevIdx = 0;
  bool _navPress = false;
  late final AnimationController _navC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void dispose() {
    _navC.dispose();
    super.dispose();
  }

  /// ✅ تبويب تفاعلي: الدائرة + الغرزة تنزلقان معاً
  void _goTab(int i) {
    if (i == _idx) return;
    setState(() {
      _prevIdx = _idx;
      _idx = i;
    });
    _navC.forward(from: 0);
  }

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
            18, 0, 18, MediaQuery.of(context).padding.bottom + 12),
        child: LayoutBuilder(
          builder: (context, cons) {
            final double W = cons.maxWidth;
            final bool rtl = Directionality.of(context) == TextDirection.rtl;
            const double pad = 24;
            final double slotInner = (W - pad * 2) / 5;
            double centerOf(int i) {
              final c = pad + slotInner * i + slotInner / 2;
              return rtl ? W - c : c;
            }

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
            return AnimatedBuilder(
              animation: _navC,
              builder: (context, _) {
                final t = Curves.easeInOutCubic.transform(_navC.value);
                final cx = centerOf(_prevIdx) +
                    (centerOf(_idx) - centerOf(_prevIdx)) * t;
                return SizedBox(
                  height: 92,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ✅ الشريط المغروز (يرسم حيّاً مع الحركة)
                      CustomPaint(
                        size: Size(W, 92),
                        painter: _NotchPainter(cx: cx, dark: dark),
                      ),
                      // ✅ الأيقونات (النشطة تتلاشى لأن الدائرة تحملها)
                      Positioned(
                        left: pad,
                        right: pad,
                        bottom: 0,
                        child: SizedBox(
                          height: 58,
                          child: Row(
                            children: List.generate(5, (i) {
                              final active = _idx == i;
                              return Expanded(
                                child: Tooltip(
                                  message: labels[i],
                                  child: InkWell(
                                    onTap: () => _goTab(i),
                                    borderRadius: BorderRadius.circular(29),
                                    child: SizedBox(
                                      height: 58,
                                      child: AnimatedOpacity(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        opacity: active ? 0 : 1,
                                        child: Icon(icons[i],
                                            size: 22,
                                            color: dark
                                                ? Colors.grey.shade300
                                                : const Color(0xFF43434E)),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      // ✅ الدائرة الطافية داخل الغرزة (تنضغط عند اللمس)
                      Positioned(
                        left: cx - 28,
                        top: 6,
                        child: GestureDetector(
                          onTapDown: (_) => setState(() => _navPress = true),
                          onTapUp: (_) => setState(() => _navPress = false),
                          onTapCancel: () =>
                              setState(() => _navPress = false),
                          onTap: () => _goTab(_idx),
                          child: Tooltip(
                            message: labels[_idx],
                            child: AnimatedScale(
                              scale: _navPress ? 0.88 : 1,
                              duration: const Duration(milliseconds: 140),
                              curve: Curves.easeOut,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: <Color>[
                                      Color(0xFFFF8C00),
                                      Color(0xFFE8446B)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE8446B)
                                          .withAlpha(dark ? 130 : 100),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: AppColors.orange.withAlpha(70),
                                      blurRadius: 34,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  switchInCurve: Curves.easeOutBack,
                                  child: Icon(
                                    icons[_idx],
                                    key: ValueKey<int>(_idx),
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
