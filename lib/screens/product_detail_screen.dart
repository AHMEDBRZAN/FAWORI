import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';
import '../data/sample_data.dart';
import '../widgets/fawori_logo.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final String? imageUrl;
  final bool canBuy;
  final VoidCallback onAdd;
  const ProductDetailScreen({
    super.key,
    required this.product,
    this.imageUrl,
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
    final AppSettings s = context.watch<AppSettings>();
    final String base = 'https://ahmedbrzan.github.io/FAWORI';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.product.name,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 1.2,
              child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                  ? Image.network('$base/assets/${widget.imageUrl}',
                      fit: BoxFit.cover, gaplessPlayback: true,
                      errorBuilder: (c, o, st) => const _PhBig())
                  : const _PhBig(),
            ),
          ),
          const SizedBox(height: 20),
          Text(widget.product.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(widget.product.desc,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 14, height: 1.6)),
          const SizedBox(height: 24),
          if (widget.canBuy) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppColors.orange),
                    onPressed: () => setState(() {
                          if (_qty > 1) _qty--;
                        })),
                Text('$_qty',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900)),
                IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppColors.orange),
                    onPressed: () => setState(() => _qty++)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: <Color>[AppColors.orange, Color(0xFFF26B0F)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.orange.withAlpha(80),
                      blurRadius: 18,
                      offset: const Offset(0, 7)),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white),
                  onPressed: () {
                    for (int i = 0; i < _qty; i++) {
                      widget.onAdd();
                    }
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 24),
                  label: Text(
                    s.isArabic ? 'أضف إلى السلة' : 'Add to cart',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withAlpha(80))),
              child: Text(
                s.isArabic
                    ? 'سجّل الدخول للشراء وإضافة المنتجات للسلة'
                    : 'Login to purchase and add to cart',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhBig extends StatelessWidget {
  const _PhBig();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.orange.withAlpha(25),
      child: const Center(child: FaworiLogo(size: 90)),
    );
  }
}
