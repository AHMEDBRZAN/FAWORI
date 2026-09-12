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
    if (r.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(r.body));
    }
  } catch (_) {}
  return {};
}

String _imgUrl(String p) {
  return '$_base/assets/$p?t=${DateTime.now().millisecondsSinceEpoch}';
}

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenProducts;
  const HomeScreen({super.key, this.onOpenProducts});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _ctrl = PageController();
  Timer? _timer;
  int _idx = 0;
  List<String> _homeImages = [];

  static const List<String> _defaultBanners = [
    'assets/images/as1.PNG',
    'assets/images/as2.PNG',
    'assets/images/as3.PNG',
    'assets/images/as4.PNG',
  ];

  int get _count {
    return _homeImages.isNotEmpty ? _homeImages.length : _defaultBanners.length;
  }

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
      });
    }
  }

  void _startAuto() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_ctrl.hasClients) return;
      if (_idx < _count - 1) {
        _ctrl.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        _timer?.cancel();
      }
    });
  }

  Widget _banner(int i) {
    if (_homeImages.isNotEmpty) {
      return Image.network(
        _imgUrl(_homeImages[i % _homeImages.length]),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => const _Fallback(),
      );
    }
    return Image.asset(
      _defaultBanners[i % _defaultBanners.length],
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => const _Fallback(),
    );
  }

  Widget _gradText(String t, double size) {
    return ShaderMask(
      shaderCallback: (r) {
        return const LinearGradient(
          colors: [AppColors.orange, AppColors.teal],
        ).createShader(r);
      },
      child: Text(
        t,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _secTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.orange, AppColors.teal],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            t,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quick(IconData ic, String label, Color c, VoidCallback? onTap) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c.withAlpha(30), Theme.of(context).colorScheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withAlpha(70)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [c, c.withAlpha(160)]),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(ic, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: c, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _brand(String ar, String en, Color c) {
    return Pressable(
      onTap: widget.onOpenProducts,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c.withAlpha(26), Theme.of(context).colorScheme.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withAlpha(60)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              en,
              style: TextStyle(
                color: c,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ar,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF141419), Color(0xFF1B1B21)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.orange, AppColors.teal],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const FaworiLogo(size: 44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _gradText(s.tr('appName'), 18)),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.orange,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withAlpha(50),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 175,
                    child: PageView.builder(
                      controller: _ctrl,
                      itemCount: _count,
                      onPageChanged: (i) {
                        setState(() {
                          _idx = i;
                        });
                        if (i >= _count - 1) {
                          _timer?.cancel();
                        }
                      },
                      itemBuilder: (_, i) => _banner(i),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _count,
                  (i) {
                    final isActive = i == _idx;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [AppColors.orange, AppColors.teal],
                              )
                            : null,
                        color: isActive ? null : Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              _secTitle(s.isArabic ? 'الوصول السريع' : 'Quick access'),
              Row(
                children: [
                  Expanded(
                    child: _quick(
                      Icons.inventory_2_rounded,
                      s.isArabic ? 'المنتجات' : 'Products',
                      AppColors.orange,
                      widget.onOpenProducts,
                    ),
                  ),
                  const SizedBox(width: 10),
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
              const SizedBox(height: 20),
              _secTitle(s.isArabic ? 'العلامات' : 'Brands'),
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
                  _brand('CADENCE', 'CADENCE', Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.orange.withAlpha(40),
      child: const Center(
        child: FaworiLogo(size: 80),
      ),
    );
  }
}
