import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/favorites.dart';
import '../core/store_service.dart';
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
    if (r.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(r.body));
    }
  } catch (_) {}
  return {};
}

String _imgUrl(String p) {
  return '$_base/assets/$p?t=${DateTime.now().millisecondsSinceEpoch}';
}

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

  static const List<String> _brands = <String>[
    'all', 'fawori', 'isomat', 'cadence', 'sibax'
  ];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final m = await _loadImgs();
    if (mounted) {
      setState(() {
        _prodMap = Map<String, String>.from(m['products'] ?? {});
      });
    }
  }

  Future<void> _uploadProduct(String pid, String pname) async {
    final f = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1000);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    try {
      final path = 'assets/images/prod_$pid.png';
      await ImagesService.putBytes(path, bytes, kUploadToken, 'product $pid');
      await ImagesService.setMapping('products', pid, path, kUploadToken);
      final m = await ImagesService.loadImages();
      if (mounted) {
        setState(() {
          _prodMap = Map<String, String>.from(m['products'] ?? {});
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('✅ تم رفع صورة: $pname')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل الرفع: $e')));
      }
    }
  }

  List<Product> get _filtered {
    return sampleProducts
        .where((Product p) =>
            (_brand == 'all' || p.brand == _brand) &&
            (p.name.contains(_query) || p.desc.contains(_query)))
        .toList();
  }

  Widget _chip(String b, AppSettings s) {
    final bool sel = _brand == b;
    final String label = b == 'all' ? (s.isArabic ? 'الكل' : 'All') : b;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Pressable(
        onTap: () {
          setState(() {
            _brand = b;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: sel
                ? const LinearGradient(
                    colors: <Color>[AppColors.orange, Color(0xFFF26B0F)])
                : null,
            color: sel ? null : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
                color: sel ? Colors.transparent : AppColors.orange.withAlpha(80)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: sel ? Colors.white : AppColors.orange,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(Product p, bool isAdmin) {
    final Favorites favs = context.watch<Favorites>();
    final bool isFav = favs.contains(p.id);
    final String? img = _prodMap[p.id];
    return Pressable(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              AppColors.orange.withAlpha(22),
              Theme.of(context).colorScheme.surface
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.orange.withAlpha(60)),
          boxShadow: [
            BoxShadow(
                color: AppColors.orange.withAlpha(20),
                blurRadius: 14,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(17)),
                    child: img != null
                        ? Image.network(_imgUrl(img), fit: BoxFit.cover,
                            errorBuilder: (BuildContext c, Object o, StackTrace? st) =>
                                const _Ph())
                        : const _Ph(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: <Widget>[
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.desc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 6,
              left: 6,
              child: IconButton(
                icon: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? Colors.red : Colors.grey,
                    size: 20),
                onPressed: () => favs.toggle(p.id),
              ),
            ),
            if (isAdmin)
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  onTap: () => _uploadProduct(p.id, p.name),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.photo_camera_rounded,
                        size: 16, color: Colors.white),
                  ),
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
    final bool isAdmin = s.isImageAdmin;
    return Scaffold(
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
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (Rect r) => const LinearGradient(
                                colors: <Color>[
                              AppColors.orange,
                              Color(0xFFF26B0F)
                            ]).createShader(r),
                        child: Text(
                          s.isArabic ? 'المنتجات' : 'Products',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                          _gifts
                              ? Icons.inventory_2_rounded
                              : Icons.redeem_rounded,
                          color: AppColors.orange),
                      onPressed: () {
                        setState(() {
                          _gifts = !_gifts;
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (!_gifts) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (String v) {
                      setState(() {
                        _query = v;
                      });
                    },
                    style: TextStyle(
                        color: dark ? Colors.white : AppColors.ink),
                    decoration: InputDecoration(
                      hintText: s.isArabic ? 'ابحث عن منتج...' : 'Search...',
                      prefixIcon:
                          const Icon(Icons.search_rounded, color: AppColors.orange),
                      filled: true,
                      fillColor:
                          dark ? const Color(0xFF26262E) : const Color(0xFFFFFDF9),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: AppColors.orange.withAlpha(80))),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _brands.map((String b) => _chip(b, s)).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Expanded(
                child: _gifts
                    ? const GiftsView()
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.72),
                        itemCount: _filtered.length,
                        itemBuilder: (BuildContext c, int i) =>
                            _card(_filtered[i], isAdmin),
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
