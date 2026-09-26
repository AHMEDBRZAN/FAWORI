import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/orders_service.dart';
import '../core/theme.dart';
import '../data/sample_data.dart';
import '../widgets/pressable.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

/// ✅ أسماء الأقسام وألوانها المميزة
class _BrandCfg {
  final String key;
  final String ar;
  final String en;
  final Color color;
  final IconData icon;
  const _BrandCfg(this.key, this.ar, this.en, this.color, this.icon);
}

const List<_BrandCfg> _brands = [
  _BrandCfg('fawori', 'فاوري', 'Fawori', Color(0xFFFF8C00),
      Icons.format_paint_rounded),
  _BrandCfg('isomat', 'آيزومات', 'Isomat', Color(0xFF2196F3),
      Icons.water_drop_rounded),
  _BrandCfg('cadence', 'كادينز', 'Cadence', Color(0xFF9C27B0),
      Icons.palette_rounded),
  _BrandCfg('sibax', 'سيباكس', 'Sibax', Color(0xFFC8961E),
      Icons.build_rounded),
];

class ProductsScreen extends StatefulWidget {
  /// ✅ اختياري: فتح الشاشة على قسم معين (تستخدمه الرئيسية)
  final String? initialBrand;
  const ProductsScreen({super.key, this.initialBrand});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  int _cartCount = 0;
  String _q = '';
  String? _focusBrand;
  final _qCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _refreshCount();
    // ✅ فتح القسم المطلوب مباشرة (يجلب ما في قائمته من الكتالوج)
    if (widget.initialBrand != null &&
        _brands.any((b) => b.key == widget.initialBrand)) {
      _focusBrand = widget.initialBrand;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollCtrl.hasClients) {
          _scrollCtrl.jumpTo(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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

  _BrandCfg _brandCfg(String key) =>
      _brands.firstWhere((b) => b.key == key);

  /// ✅ فلترة منتجات قسم معين (البحث يعمل داخل القسم فقط)
  List<Product> _filterBrand(String brandKey) {
    final base = sampleData.where((p) => p.brand == brandKey);
    if (_q.trim().isEmpty) return base.toList();
    final q = _q.trim().toLowerCase();
    return base
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q))
        .toList();
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
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(16),
        children: [
          // ===== شريط البحث =====
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
              controller: _qCtrl,
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
                suffixIcon: _q.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: Colors.red, size: 18),
                        onPressed: () {
                          _qCtrl.clear();
                          setState(() => _q = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ===== شريط القسم المركّز (عند الفتح من الرئيسية) =====
          if (_focusBrand != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      _brandCfg(_focusBrand!).color,
                      _brandCfg(_focusBrand!).color.withAlpha(220),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _brandCfg(_focusBrand!).color.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(_brandCfg(_focusBrand!).icon,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.isArabic
                            ? '${_brandCfg(_focusBrand!).ar} — ${_filterBrand(_focusBrand!).length} مادة'
                            : '${_brandCfg(_focusBrand!).en} — ${_filterBrand(_focusBrand!).length} items',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Colors.white),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _focusBrand = null),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.apps_rounded,
                                size: 16, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                                s.isArabic ? 'كل الأقسام' : 'All',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ===== الأقسام (المركّز عليها أو الكل) =====
          for (final b in (_focusBrand == null
              ? _brands
              : _brands.where((x) => x.key == _focusBrand).toList()))
            _buildSection(b, dark, s),
        ],
      ),
    );
  }

  /// ✅ بناء قسم واحد (رأس متدرج + شبكة منتجات)
  Widget _buildSection(_BrandCfg b, bool dark, AppSettings s) {
    final items = _filterBrand(b.key);
    // ✅ إخفاء القسم الفارغ عند البحث
    if (items.isEmpty && _q.trim().isNotEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== رأس القسم =====
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[b.color, b.color.withAlpha(220)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: b.color.withAlpha(80),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(b.icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.isArabic ? b.ar : b.en,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${items.length} ${s.isArabic ? 'مادة' : 'items'}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ===== حالة فارغة =====
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1E1E28) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: b.color.withAlpha(40)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(b.icon, color: b.color.withAlpha(80), size: 48),
                    const SizedBox(height: 8),
                    Text(
                        s.isArabic ? 'لا توجد منتجات' : 'No products',
                        style: TextStyle(
                            color: dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            )

          // ===== شبكة المنتجات =====
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final p = items[i];
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
                          border: Border.all(color: b.color.withAlpha(50)),
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
                                child:
                                    Icon(b.icon, size: 46, color: b.color),
                              ),
                            ),
                            Text(p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: dark
                                        ? Colors.white
                                        : AppColors.ink)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: b.color.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(s.isArabic ? b.ar : b.en,
                                  style: TextStyle(
                                      color: b.color,
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
                              gradient: LinearGradient(colors: <Color>[
                                b.color,
                                b.color.withAlpha(220)
                              ]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: b.color.withAlpha(90),
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
