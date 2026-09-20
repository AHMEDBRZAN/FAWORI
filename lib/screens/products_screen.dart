import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/orders_service.dart';
import '../core/theme.dart';
import '../data/sample_data.dart';
import '../widgets/pressable.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  int _cartCount = 0;
  String _q = '';

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

  /// ✅ إضافة عبر الدالة المركزية المتسلسلة
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
    final list = _q.trim().isEmpty
        ? sampleData
        : sampleData
            .where((p) =>
                p.name.toLowerCase().contains(_q.trim().toLowerCase()) ||
                p.brand.toLowerCase().contains(_q.trim().toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor:
          dark ? const Color(0xFF141419) : const Color(0xFFFFF8F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(s.isArabic ? 'المنتجات' : 'Products',
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
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: dark
                    ? <Color>[
                        const Color(0xFF1E1E28),
                        const Color(0xFF26262E)
                      ]
                    : <Color>[Colors.white, const Color(0xFFFFF8F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border:
                  Border.all(color: AppColors.orange.withAlpha(60), width: 1.2),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              style: TextStyle(
                  color: dark ? Colors.white : AppColors.ink, fontSize: 15),
              decoration: InputDecoration(
                hintText:
                    s.isArabic ? 'ابحث عن مادة...' : 'Search product...',
                hintStyle: TextStyle(
                    color: dark ? Colors.grey.shade500 : Colors.grey.shade400),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.orange),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final p = list[i];
              // ✅ البطاقة وزر الإضافة طبقتان منفصلتان — لا لمسة مزدوجة
              return Stack(
                children: [
                  Pressable(
                    onTap: () => _openDetail(p),
                    child: Container(
                      height: double.infinity,
                      padding: const EdgeInsets.all(14),
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
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: AppColors.orange.withAlpha(50)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(dark ? 50 : 10),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Center(
                              child: Icon(Icons.format_paint_rounded,
                                  size: 46, color: AppColors.orange),
                            ),
                          ),
                          Text(p.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color:
                                      dark ? Colors.white : AppColors.ink)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(p.brand,
                                style: const TextStyle(
                                    color: AppColors.teal,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    bottom: 10,
                    end: 10,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _addToCart(p, 1),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: <Color>[
                                  Color(0xFFFF8C00),
                                  Color(0xFFF26B0F)
                                ]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.orange.withAlpha(90),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3)),
                            ],
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
