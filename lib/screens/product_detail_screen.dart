import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';
import '../data/sample_data.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final bool canBuy;
  final void Function(int qty) onAdd;
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.canBuy,
    required this.onAdd,
  });
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.product;

    return Scaffold(
      backgroundColor:
          dark ? const Color(0xFF141419) : const Color(0xFFFFF8F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(p.name,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: dark ? Colors.white : AppColors.ink)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1E1E28) : const Color(0xFFE7E3DE),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Image.asset(
                'assets/logo.png',
                width: 120,
                height: 120,
                errorBuilder: (_, __, ___) => Icon(
                    Icons.format_paint_rounded,
                    size: 90,
                    color: AppColors.orange),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(p.name,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: dark ? Colors.white : AppColors.ink)),
          const SizedBox(height: 8),
          Text(p.desc,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.teal.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(p.brand,
                style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 24),
          if (widget.canBuy) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: _qty > 1 ? () => setState(() => _qty--) : null,
                  child: Icon(Icons.remove_circle_outline,
                      color: _qty > 1 ? AppColors.orange : Colors.grey,
                      size: 30),
                ),
                const SizedBox(width: 20),
                Text('$_qty',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: dark ? Colors.white : AppColors.ink)),
                const SizedBox(width: 20),
                InkWell(
                  onTap: _qty < 99 ? () => setState(() => _qty++) : null,
                  child: Icon(Icons.add_circle_outline,
                      color: _qty < 99 ? AppColors.orange : Colors.grey,
                      size: 30),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: <Color>[
                    Color(0xFFE8A33C),
                    Color(0xFFF26B0F)
                  ]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.orange.withAlpha(80),
                        blurRadius: 16,
                        offset: const Offset(0, 6)),
                  ]),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white),
                  onPressed: () => widget.onAdd(_qty),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: Text(
                      s.isArabic ? 'أضف إلى السلة' : 'Add to cart',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(dark ? 40 : 20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withAlpha(70)),
              ),
              child: Text(
                  s.isArabic
                      ? 'سجّل الدخول للشراء من هذا المنتج'
                      : 'Login to purchase this product',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: dark ? Colors.white : Colors.red.shade400,
                      fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}
