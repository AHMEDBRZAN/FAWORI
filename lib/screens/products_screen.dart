import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/favorites.dart';
import '../core/theme.dart';
import '../data/sample_data.dart';
import '../widgets/fawori_logo.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  bool _productsTab = true;
  String _brand = 'fawori';
  String _category = 'all';
  String _query = '';

  final List<String> _brands = ['fawori', 'isomat', 'cadence', 'sibax'];
  final List<String> _cats = ['all', 'primers', 'interior', 'exterior'];

  List<Product> get _filtered => sampleProducts
      .where((p) =>
          p.brand == _brand &&
          (_category == 'all' || p.category == _category) &&
          p.name.contains(_query))
      .toList();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
                child: Text(s.tr('productsAndGifts'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
            const SizedBox(height: 16),
            _segment(s),
            const SizedBox(height: 12),
            _search(s),
            const SizedBox(height: 12),
            _brandChips(s),
            const SizedBox(height: 12),
            _catRow(s),
            const SizedBox(height: 12),
            Expanded(
                child: _productsTab
                    ? _grid()
                    : Center(child: Text(s.tr('giftsSoon')))),
          ],
        ),
      ),
    );
  }

  Widget _segment(AppSettings s) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Expanded(child: _segBtn(s.tr('products'), Icons.inventory_2_rounded, true)),
          const SizedBox(width: 10),
          Expanded(child: _segBtn(s.tr('gifts'), Icons.redeem_rounded, false)),
        ]),
      );

  Widget _segBtn(String t, IconData ic, bool isProducts) {
    final active = _productsTab == isProducts;
    return InkWell(
      onTap: () => setState(() => _productsTab = isProducts),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: active ? AppColors.orange : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(ic, color: active ? Colors.black : Colors.grey, size: 22),
          const SizedBox(width: 8),
          Text(t,
              style: TextStyle(
                  color: active ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _search(AppSettings s) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: s.tr('searchProduct'),
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
        ),
      );

  Widget _brandChips(AppSettings s) => SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _brands.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final b = _brands[i];
            final active = b == _brand;
            return InkWell(
              onTap: () => setState(() => _brand = b),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.orange : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(s.tr('brand_$b'),
                    style: TextStyle(
                        color: active ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            );
          },
        ),
      );

  Widget _catRow(AppSettings s) => SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _cats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final c = _cats[i];
            final active = c == _category;
            return InkWell(
              onTap: () => setState(() => _category = c),
              child: Container(
                width: 110,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: active ? AppColors.orange : Colors.transparent, width: 1.5),
                ),
                child: Column(children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.orange.withAlpha(active ? 40 : 20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                          c == 'all' ? Icons.grid_view_rounded : Icons.format_paint_rounded,
                          color: AppColors.orange),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(s.tr(c), style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ),
            );
          },
        ),
      );

  Widget _grid() => _filtered.isEmpty
      ? Center(
          child: Text(context.watch<AppSettings>().tr('noProducts'),
              style: const TextStyle(color: Colors.grey)))
      : GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          itemCount: _filtered.length,
          itemBuilder: (_, i) => _productCard(_filtered[i]),
        );

  Widget _productCard(Product p) {
    final favs = context.watch<Favorites>();
    final isFav = favs.contains(p.id);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: [
        Stack(children: [
          Container(
            height: 170,
            margin: const EdgeInsets.all(10),
            decoration:
                BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: FaworiLogo(size: 90)),
          ),
          PositionedDirectional(
            top: 8,
            start: 8,
            child: IconButton(
              style: IconButton.styleFrom(
                  backgroundColor: Colors.black26, shape: const CircleBorder()),
              icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? AppColors.red : Colors.white, size: 20),
              onPressed: () => favs.toggle(p.id),
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(p.desc,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ),
      ]),
    );
  }
}
