import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';
import '../widgets/fawori_logo.dart';
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

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenProducts;
  const HomeScreen({super.key, this.onOpenProducts});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _ctrl = PageController();
  int _idx = 0;
  Timer? _timer;
  List<String> _homeImages = [];

  static const List<String> _defaultBanners = [
    'assets/images/as1.PNG', 'assets/images/as2.PNG',
    'assets/images/as3.PNG', 'assets/images/as4.PNG',
  ];

  @override
  void initState() {
    super.initState();
    _loadImages();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_ctrl.hasClients) {
        _ctrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() { _timer?.cancel(); _ctrl.dispose(); super.dispose(); }

  Future<void> _loadImages() async {
    final m = await _loadImgs();
    if (mounted) setState(() => _homeImages = List<String>.from(m['home'] ?? []));
  }

  int get _count => _homeImages.isNotEmpty ? _homeImages.length : _defaultBanners.length;

  Widget _banner(int i) {
    if (_homeImages.isNotEmpty) {
      return Image.network(_imgUrl(_homeImages[i % _homeImages.length]),
          fit: BoxFit.cover, width: double.infinity,
          errorBuilder: (_, __, ___) => const _Fallback());
    }
    return Image.asset(_defaultBanners[i % _defaultBanners.length],
        fit: BoxFit.cover, width: double.infinity,
        errorBuilder: (_, __, ___) => const _Fallback());
  }

  Widget _quick(IconData ic, String label, Color c, VoidCallback? onTap) => Pressable(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border(context))),
          child: Row(children: [
            Icon(ic, color: c, size: 26),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
          ])));

  Widget _brand(String ar, String en, Color c) => Pressable(
      onTap: widget.onOpenProducts,
      child: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border(context))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(en, style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(ar, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ])));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Scaffold(
      body: SafeArea(
          bottom: false,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/logo.png', width: 44, height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const FaworiLogo(size: 44))),
              const SizedBox(width: 10),
              Expanded(child: Text(s.tr('appName'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
              IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () {}),
            ]),
            const SizedBox(height: 14),
            SizedBox(
                height: 170,
                child: PageView.builder(
                    controller: _ctrl,
                    itemCount: _count,
                    onPageChanged: (i) => setState(() => _idx = i),
                    itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(18), child: _banner(i)))),
            const SizedBox(height: 8),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    _count,
                    (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _idx ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                            color: i == _idx ? AppColors.orange : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(4))))),
            const SizedBox(height: 18),
            Text(s.isArabic ? 'الوصول السريع' : 'Quick access',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _quick(Icons.inventory_2_rounded,
                  s.isArabic ? 'المنتجات' : 'Products', AppColors.orange, widget.onOpenProducts)),
              const SizedBox(width: 10),
              Expanded(child: _quick(Icons.redeem_rounded,
                  s.isArabic ? 'الهدايا' : 'Gifts', AppColors.teal, widget.onOpenProducts)),
            ]),
            const SizedBox(height: 18),
            Text(s.isArabic ? 'العلامات' : 'Brands',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.15,
                children: [
                  _brand('فاوري', 'FAWORI', AppColors.orange),
                  _brand('الهدايا', 'GIFTS', AppColors.teal),
                  _brand('isomat', 'ISOMAT', Colors.red.shade400),
                  _brand('CADENCE', 'CADENCE', Colors.grey.shade500),
                ]),
          ])),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();
  @override
  Widget build(BuildContext context) => Container(
      color: AppColors.orange.withAlpha(40),
      child: const Center(child: FaworiLogo(size: 80)));
}
