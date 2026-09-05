import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/favorites.dart';
import '../core/locked_dialog.dart';
import '../core/theme.dart';
import '../data/sample_data.dart';
import '../widgets/fawori_logo.dart';
import '../widgets/gifts_view.dart';
import '../widgets/pressable.dart';

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
            const SizedBox(height: 12),
            Center(
                child: Text(s.tr('productsAndGifts'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
            const SizedBox(height: 12),
            _segment(s),
            const SizedBox(height: 10),
            if (_productsTab) ...[
              _search(s),
              const SizedBox(height: 10),
              _brandChips(s),
              const SizedBox(height: 10),
              _catRow(s),
              const SizedBox(height: 10),
              Expanded(child: _grid()),
            ] else ...[
              const SizedBox(height: 4),
              const Expanded(child: GiftsView()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _segment(AppSettings s) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(child: _segBtn(s.tr('products'), Icons.inventory_2_rounded, true)),
          const SizedBox(width: 8),
          Expanded(child: _segBtn(s.tr('gifts'), Icons.redeem_rounded, false)),
        ]),
      );

  Widget _segBtn(String t, IconData ic, bool isProducts) {
    final active = _productsTab == isProducts;
    return Pressable(
      onTap: () => setState(() => _productsTab = isProducts),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: active ? AppColors.orange : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? Colors.transparent : AppTheme.border(context)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(ic, color: active ? Colors.black : Colors.grey, size: 18),
          const SizedBox(width: 6),
          Text(t,
              style: TextStyle(
                  color: active ? Colors.black : AppTheme.text(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _search(AppSettings s) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: s.tr('searchProduct'),
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
            ),
          ),
        ),
      );

  Widget _brandChips(AppSettings s) => SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _brands.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final b = _brands[i];
            final active = b == _brand;
            return Pressable(
              onTap: () => setState(() => _brand = b),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.orange : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: active ? Colors.transparent : AppTheme.border(context)),
                ),
                child: Text(s.tr('brand_$b'),
                    style: TextStyle(
                        color: active ? Colors.black : AppTheme.text(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            );
          },
        ),
      );

  Widget _catRow(AppSettings s) => SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _cats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final c = _cats[i];
            final active = c == _category;
            return Pressable(
              onTap: () => setState(() => _category = c),
              child: Container(
                width: 86,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: active ? AppColors.orange : AppTheme.border(context),
                      width: active ? 1.5 : 1),
                ),
                child: Column(children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.orange.withAlpha(active ? 40 : 18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                          c == 'all' ? Icons.grid_view_rounded : Icons.format_paint_rounded,
                          color: AppColors.orange, size: 22),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(s.tr(c),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: _filtered.length,
          itemBuilder: (_, i) => _productCard(_filtered[i]),
        );

  Widget _productCard(Product p) {
    final favs = context.watch<Favorites>();
    final isFav = favs.contains(p.id);
    return Pressable(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(children: [
              Container(
                height: 130,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset('assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Center(child: FaworiLogo(size: 70))),
                ),
              ),
              PositionedDirectional(
                top: 6,
                start: 6,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.black26, shape: const CircleBorder()),
                  icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? AppColors.red : Colors.white,
                      size: 16),
                  onPressed: () {
                    final s = context.read<AppSettings>();
                    if (s.isGuest) {
                      showLockedDialog(context, s);
                      return;
                    }
                    favs.toggle(p.id);
                  },
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(p.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(p.desc,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }
}
