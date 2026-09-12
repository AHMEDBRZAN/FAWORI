import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/favorites.dart';
import '../core/theme.dart';
import '../data/sample_data.dart';
import '../widgets/fawori_logo.dart';
import '../widgets/gifts_view.dart';
import '../widgets/pressable.dart';

const String _base = 'https://ahmedbrzan.github.io/FAWORI';

Future<Map<String, dynamic>> _loadImgs() async {
  try {
    final r = await http.get(Uri.parse(
        '$_base/assets/assets/data/images.json?t=${DateTime.now().millisecondsSinceEpoch}'));
    if (r.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(r.body));
  } catch (_) {}
  return {};
}

String _imgUrl(String p) =>
    '$_base/assets/$p?t=${DateTime.now().millisecondsSinceEpoch}';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  bool _gifts = false;
  String _query = '';
  String _brand = 'all';
  Map<String, String> _prodMap = {};

  static const List<String> _brands = ['all', 'fawori', 'isomat', 'cadence', 'sibax'];

  @override
  void initState() { super.initState(); _loadImages(); }

  Future<void> _loadImages() async {
    final m = await _loadImgs();
    if (mounted) setState(() => _prodMap = Map<String, String>.from(m['products'] ?? {}));
  }

  List<Product> get _filtered => sampleProducts
      .where((p) => (_brand == 'all' || p.brand == _brand) &&
          (p.name.contains(_query) || p.desc.contains(_query)))
      .toList();

  Widget _card(Product p) {
    final favs = context.watch<Favorites>();
    final isFav = favs.contains(p.id);
    final img = _prodMap[p.id];
    return Pressable(
      child: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border(context))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
                child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                    child: img != null
                        ? Image.network(_imgUrl(img), fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const _Ph())
                        : const _Ph())),
            Padding(
                padding: const EdgeInsets.all(8),
                child: Column(children: [
                  Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(p.desc, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ])),
            Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                    icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? Colors.red : Colors.grey, size: 20),
                    onPressed: () => favs.toggle(p.id))),
          ])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Scaffold(
      appBar: AppBar(
          title: Text(s.isArabic ? 'المنتجات' : 'Products'),
          actions: [
            IconButton(
                icon: Icon(_gifts ? Icons.inventory_2_rounded : Icons.redeem_rounded),
                onPressed: () => setState(() => _gifts = !_gifts))
          ]),
      body: _gifts
          ? const GiftsView()
          : Column(children: [
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                          hintText: s.isArabic ? 'ابحث عن منتج...' : 'Search...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface))),
              SizedBox(
                  height: 40,
                  child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: _brands
                          .map((b) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ChoiceChip(
                                  label: Text(b == 'all' ? (s.isArabic ? 'الكل' : 'All') : b),
                                  selected: _brand == b,
                                  onSelected: (_) => setState(() => _brand = b))))
                          .toList())),
              const SizedBox(height: 8),
              Expanded(
                  child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.72),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _card(_filtered[i]))),
            ]),
    );
  }
}

class _Ph extends StatelessWidget {
  const _Ph();
  @override
  Widget build(BuildContext context) => Container(
      color: AppColors.orange.withAlpha(25),
      child: const Center(child: FaworiLogo(size: 56)));
}
