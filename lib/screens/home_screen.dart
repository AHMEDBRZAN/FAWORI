import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/store_service.dart';
import '../core/theme.dart';
import '../widgets/fawori_logo.dart';
import '../widgets/pressable.dart';

const String _base = 'https://ahmedbrzan.github.io/FAWORI';
const int _kPages = 10000;
const int _kStart = 1000;

// 🚀 نظام كاش متقدم للصور
class _AdvancedImageCache {
  final Map<String, ImageProvider> _cache = {};
  
  ImageProvider getProvider(String url) {
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }
    final provider = NetworkImage(url);
    _cache[url] = provider;
    return provider;
  }
  
  void preload(String url) {
    if (!_cache.containsKey(url)) {
      precacheImage(NetworkImage(url), _dummyContext);
    }
  }
  
  static final BuildContext _dummyContext = GlobalKey().currentContext!;
}

final _AdvancedImageCache _imgCache = _AdvancedImageCache();

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

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenProducts;
  const HomeScreen({super.key, this.onOpenProducts});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _ctrl = PageController(initialPage: _kStart);
  Timer? _timer;
  int _idx = 0;
  List<String> _homeImages = [];
  Map<String, String> _brandMap = {};
  bool _imagesLoaded = false;

  static const List<String> _defaultBanners = <String>[
    'assets/images/as1.PNG',
    'assets/images/as2.PNG',
    'assets/images/as3.PNG',
    'assets/images/as4.PNG',
  ];

  int get _count =>
      _homeImages.isNotEmpty ? _homeImages.length : _defaultBanners.length;

  @override
  void initState() {
    super.initState();
    _loadImages();
    _startAuto();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    final m = await _loadImgs();
    if (mounted) {
      setState(() {
        _homeImages = List<String>.from(m['home'] ?? []);
        _brandMap = Map<String, String>.from(m['brands'] ?? {});
        _imagesLoaded = true;
      });
      
      // 🚀 تحميل فوري للبانر الأول
      if (_homeImages.isNotEmpty) {
        _imgCache.preload(_imgUrl(_homeImages[0]));
      }
      
      // تحميل مسبق للباقي
      for (final img in _homeImages.skip(1).take(4)) {
        _imgCache.preload(_imgUrl(img));
      }
    }
  }

  void _startAuto() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_ctrl.hasClients) return;
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _uploadBrand(String key) async {
    String tk = await ImagesService.resolveToken();
    if (tk.isEmpty) {
      final t = await ImagesService.askGitHubToken(context);
      if (t == null) return;
      tk = t;
    }
    final f = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 600);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    try {
      final path = 'assets/images/brand_$key.png';
      await ImagesService.putBytes(path, bytes, tk, 'brand $key');
      await ImagesService.setMapping('brands', key, path, tk);
      final m = await _loadImgs();
      if (mounted) {
        setState(() {
          _brandMap = Map<String, String>.from(m['brands'] ?? {});
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('✅ تم رفع صورة $key')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل الرفع: $e')));
      }
    }
  }

  // 🎯 بانر سريع التحميل
  Widget _banner(int real) {
    String url;
    if (_homeImages.isNotEmpty) {
      url = _imgUrl(_homeImages[real % _homeImages.length]);
    } else {
      url = _defaultBanners[real % _defaultBanners.length];
    }
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.orange.withAlpha(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image(
          image: _imgCache.getProvider(url),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: AppColors.orange.withAlpha(20),
              child: const Center(
                child: FaworiLogo(size: 60),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) =>
              const Center(child: FaworiLogo(size: 60)),
        ),
      ),
    );
  }

  Widget _gradText(String t, double size) {
    return ShaderMask(
      shaderCallback: (Rect r) =>
          const LinearGradient(colors: <Color>[AppColors.orange, Color(0xFFF26B0F)])
              .createShader(r),
      child: Text(
        t,
        style: TextStyle(
            fontSize: size, fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }

  Widget _secTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[AppColors.orange, Color(0xFFF26B0F)],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            t,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _quick(IconData ic, String label, Color c, VoidCallback? onTap) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[c.withAlpha(40), Theme.of(context).colorScheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.withAlpha(100), width: 1.5),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: <Color>[c, c.withAlpha(180)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(ic, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            Icon(Icons.chevron_left_rounded, color: c, size: 22),
          ],
        ),
      ),
    );
  }

  // 🎯 علامة ثابتة - لا تتقلب
  Widget _brand(String key, String ar, String en, Color c, bool isAdmin) {
    final String? img = _brandMap[key];
    return Pressable(
      onTap: widget.onOpenProducts,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.withAlpha(100), width: 2),
        ),
        child: Stack(
          children: <Widget>[
            // صورة العلامة - ثابتة
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: img != null
                    ? Image(
                        image: _imgCache.getProvider(_imgUrl(img)),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: c.withAlpha(20),
                            child: Center(
                              child: Text(en,
                                  style: TextStyle(
                                      color: c,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900)),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            _brandText(en, ar, c),
                      )
                    : _brandText(en, ar, c),
              ),
            ),
            if (isAdmin)
              Positioned(
                bottom: 8,
                right: 8,
                child: InkWell(
                  onTap: () => _uploadBrand(key),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.photo_camera_rounded,
                        size: 18, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _brandText(String en, String ar, Color c) {
    return Container(
      color: c.withAlpha(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(en,
              style: TextStyle(color: c, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(ar, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: <Color>[AppColors.orange, Color(0xFFF26B0F)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _gradText(s.tr('appName'), 18)),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: AppColors.orange),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // 🎯 البانر المتقلب فقط
              SizedBox(
                height: 180,
                child: PageView.builder(
                  controller: _ctrl,
                  itemCount: _kPages,
                  onPageChanged: (int i) {
                    setState(() {
                      _idx = i % _count;
                    });
                  },
                  itemBuilder: (BuildContext c, int i) => _banner(i),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_count, (int i) {
                  final bool active = i == _idx;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: active
                          ? const LinearGradient(
                              colors: <Color>[AppColors.orange, Color(0xFFF26B0F)])
                          : null,
                      color: active ? null : Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              _secTitle(s.isArabic ? 'الوصول السريع' : 'Quick access'),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _quick(
                      Icons.inventory_2_rounded,
                      s.isArabic ? 'المنتجات' : 'Products',
                      AppColors.orange,
                      widget.onOpenProducts,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quick(
                      Icons.redeem_rounded,
                      s.isArabic ? 'الهدايا' : 'Gifts',
                      AppColors.teal,
                      widget.onOpenProducts,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              _secTitle(s.isArabic ? 'العلامات' : 'Brands'),
              //  العلامات ثابتة - لا تتقلب
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: <Widget>[
                  _brand('fawori', 'فاوري', 'FAWORI', AppColors.orange, isAdmin),
                  _brand('gifts', 'الهدايا', 'GIFTS', AppColors.teal, isAdmin),
                  _brand('isomat', 'isomat', 'ISOMAT', Colors.red.shade400, isAdmin),
                  _brand('cadence', 'CADENCE', 'CADENCE', Colors.grey.shade500, isAdmin),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
