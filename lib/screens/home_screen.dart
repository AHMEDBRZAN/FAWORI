import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/orders_service.dart';
import '../core/theme.dart';
import '../data/sample_data.dart';
import '../widgets/pressable.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'products_screen.dart';

class HomeScreen extends StatefulWidget {
  /// ✅ اختياري: تستخدمه main_screen للانتقال لتبويب المنتجات
  final VoidCallback? onOpenProducts;
  const HomeScreen({super.key, this.onOpenProducts});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  Future<void> _refreshCount() async {
    final s = context.read<AppSettings>();
    try {
      final cart = await OrdersService.loadCart(s.user?.id ?? '');
      if (mounted) {
        setState(() => _cartCount = cart.fold(0, (p, c) => p + c.qty));
      }
    } catch (_) {}
  }

  Future<void> _addToCart(Product p, int qty) async {
    final s = context.read<AppSettings>();
    final uid = s.user?.id ?? '';
    if (uid.isEmpty || s.isGuest) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(s.isArabic
                ? 'سجّل الدخول أولاً للشراء'
                : 'Login first to buy')));
      }
      return;
    }
    await OrdersService.addToCart(uid, p.id, p.name, '', p.brand, qty);
    await _refreshCount();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.isArabic
              ? '✅ أُضيف إلى السلة: ${p.name}'
              : 'Added: ${p.name}')));
    }
  }

  Future<void> _openCart() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const CartScreen()));
    await _refreshCount();
  }

  Future<void> _openProducts() async {
    if (widget.onOpenProducts != null) {
      widget.onOpenProducts!();
      return;
    }
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ProductsScreen()));
    await _refreshCount();
  }

  Future<void> _openDetail(Product p) async {
    final s = context.read<AppSettings>();
    final canBuy = s.user != null && s.user!.role != 'guest';
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
                product: p,
                canBuy: canBuy,
                onAdd: (q) => _addToCart(p, q))));
    await _refreshCount();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          dark ? const Color(0xFF141419) : const Color(0xFFFFF8F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(s.isArabic ? 'الرئيسية' : 'Home',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: dark ? Colors.white : AppColors.ink)),
        actions: [
          IconButton(
            onPressed: _openCart,
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart_outlined,
                    color: AppColors.orange, size: 24),
                if (_cartCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text('$_cartCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFF26B0F), Color(0xFFE8A33C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withAlpha(80),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    s.isArabic
                        ? 'مرحباً ${s.user?.name ?? 'ضيف'} 👋'
                        : 'Hello ${s.user?.name ?? 'Guest'} 👋',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          s.isArabic
                              ? 'مواد بناء أصلية بنظام نقاط مكافآت'
                              : 'Genuine materials with rewards points',
                          style: TextStyle(
                              color: Colors.white.withAlpha(220),
                              fontSize: 12)),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text('${fmtThousands(s.points)} ⭐',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Pressable(
                  onTap: _openProducts,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          AppColors.teal.withAlpha(dark ? 50 : 30),
                          AppColors.teal.withAlpha(dark ? 20 : 10),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: AppColors.teal.withAlpha(70)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.storefront_rounded,
                            color: AppColors.teal, size: 28),
                        const SizedBox(height: 6),
                        Text(s.isArabic ? 'المنتجات' : 'Products',
                            style: TextStyle(
                                color: dark ? Colors.white : AppColors.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Pressable(
                  onTap: _openCart,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          AppColors.orange.withAlpha(dark ? 50 : 30),
                          AppColors.orange.withAlpha(dark ? 20 : 10),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: AppColors.orange.withAlpha(70)),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            const Icon(Icons.shopping_cart_rounded,
                                color: AppColors.orange, size: 28),
                            if (_cartCount > 0)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle),
                                  child: Text('$_cartCount',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(s.isArabic ? 'السلة' : 'Cart',
                            style: TextStyle(
                                color: dark ? Colors.white : AppColors.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(s.isArabic ? 'منتجات مميزة' : 'Featured',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: dark ? Colors.white : AppColors.ink)),
          const SizedBox(height: 10),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sampleData.length > 8 ? 8 : sampleData.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final p = sampleData[i];
                return Stack(
                  children: [
                    Pressable(
                      onTap: () => _openDetail(p),
                      child: Container(
                        width: 150,
                        height: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: dark
                                ? <Color>[
                                    const Color(0xFF1E1E28),
                                    const Color(0xFF26262E)
                                  ]
                                : <Color>[
                                    Colors.white,
                                    const Color(0xFFFFF8F1)
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: AppColors.orange.withAlpha(50)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Center(
                                child: Icon(Icons.format_paint_rounded,
                                    size: 40, color: AppColors.orange),
                              ),
                            ),
                            Text(p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: dark
                                        ? Colors.white
                                        : AppColors.ink)),
                            const SizedBox(height: 6),
                            Text(p.brand,
                                style: const TextStyle(
                                    color: AppColors.teal,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      bottom: 8,
                      end: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _addToCart(p, 1),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: <Color>[
                                    Color(0xFFFF8C00),
                                    Color(0xFFF26B0F)
                                  ]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
