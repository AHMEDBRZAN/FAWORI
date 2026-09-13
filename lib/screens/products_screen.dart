import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/favorites.dart';
import '../core/store_service.dart';
import '../core/theme.dart';
import '../data/sample_data.dart';
import '../widgets/fawori_logo.dart';
import '../widgets/pressable.dart';

const String _base = 'https://ahmedbrzan.github.io/FAWORI';
final String _cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();
String _imgUrl(String p) => '$_base/assets/$p?t=$_cacheBuster';

const Map<String, String> _brandAr = {
  'fawori': 'فاوري',
  'isomat': 'آيزومات',
  'cadence': 'كادينز',
  'sibax': 'سيباكس',
};
const Map<String, String> _brandEn = {
  'fawori': 'FAWORI',
  'isomat': 'ISOMAT',
  'cadence': 'CADENCE',
  'sibax': 'SIBAX',
};
const Map<String, Color> _brandColor = {
  'fawori': AppColors.orange,
  'isomat': Color(0xFFE5484D),
  'cadence': Color(0xFF9B59B6),
  'sibax': Color(0xFFC8961E),
};
const List<String> _brandKeys = ['all', 'fawori', 'isomat', 'cadence', 'sibax'];

class ProductsScreen extends StatefulWidget {
  final String? initialBrand;
  const ProductsScreen({super.key, this.initialBrand});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _query = '';
  late String _brand = widget.initialBrand ?? 'all';
  Map<String, String> _prodMap = {};

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final r = await http.get(Uri.parse(
          '$_base/assets/assets/data/images.json?t=$_cacheBuster'));
      if (r.statusCode == 200) {
        final m = Map<String, dynamic>.from(jsonDecode(r.body));
        if (mounted) {
          setState(() {
            _prodMap = Map<String, String>.from(m['products'] ?? {});
          });
        }
      }
    } catch (_) {}
  }

  String _brandLabel(String b, bool isAr) {
    if (b == 'all') return isAr ? 'الكل' : 'All';
    return isAr ? (_brandAr[b] ?? b) : (_brandEn[b] ?? b);
  }

  List<Product> get _filtered => sampleProducts
      .where((Product p) =>
          (_brand == 'all' || p.brand == _brand) &&
          (p.name.contains(_query) || p.desc.contains(_query)))
      .toList();

  Widget _chip(String b, AppSettings s) {
    final bool sel = _brand == b;
    final Color c = b == 'all' ? AppColors.orange : (_brandColor[b] ?? AppColors.orange);
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 0),
      child: Pressable(
        onTap: () {
          setState(() {
            _brand = b;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: sel
                ? LinearGradient(colors: <Color>[c, c.withAlpha(180)])
                : null,
            color: sel ? null : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
                color: sel ? Colors.transparent : c.withAlpha(90), width: 1.5),
          ),
          child: Text(
            _brandLabel(b, s.isArabic),
            style: TextStyle(
              color: sel ? Colors.white : c,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(Product p) {
    final Favorites favs = context.watch<Favorites>();
    final bool isFav = favs.contains(p.id);
    final String? img = _prodMap[p.id];
    final Color c = _brandColor[p.brand] ?? AppColors.orange;
    final AppSettings s = context.watch<AppSettings>();
    return Pressable(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              c.withAlpha(25),
              Theme.of(context).colorScheme.surface
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.withAlpha(70), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: c.withAlpha(25),
                blurRadius: 12,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: img != null && img.isNotEmpty
                    ? Image.network(_imgUrl(img), fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (c2, o, st) => const _Ph())
                    : const _Ph(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(children: <Widget>[
                Text(p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s.isArabic
                        ? (_brandAr[p.brand] ?? p.brand)
                        : (_brandEn[p.brand] ?? p.brand),
                    style: TextStyle(
                        color: c, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ]),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? Colors.red : Colors.grey,
                    size: 20),
                onPressed: () => favs.toggle(p.id),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings s = context.watch<AppSettings>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: s.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: ShaderMask(
            shaderCallback: (Rect r) => const LinearGradient(
                    colors: <Color>[AppColors.orange, Color(0xFFF26B0F)])
                .createShader(r),
            child: Text(
              s.isArabic ? 'المنتجات' : 'Products',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: dark
                  ? const <Color>[Color(0xFF23232B), Color(0xFF2B2B34)]
                  : const <Color>[Color(0xFFFFF8F1), Color(0xFFFDEFDE)],
            ),
          ),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (String v) {
                    setState(() {
                      _query = v;
                    });
                  },
                  style: TextStyle(color: dark ? Colors.white : AppColors.ink),
                  decoration: InputDecoration(
                    hintText: s.isArabic ? 'ابحث عن منتج...' : 'Search...',
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: AppColors.orange),
                    filled: true,
                    fillColor:
                        dark ? const Color(0xFF26262E) : const Color(0xFFFFFDF9),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: AppColors.orange.withAlpha(80))),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _brandKeys.map((String b) => _chip(b, s)).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72),
                  itemCount: _filtered.length,
                  itemBuilder: (BuildContext c, int i) => _card(_filtered[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ph extends StatelessWidget {
  const _Ph();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.orange.withAlpha(25),
      child: const Center(child: FaworiLogo(size: 56)),
    );
  }
}
