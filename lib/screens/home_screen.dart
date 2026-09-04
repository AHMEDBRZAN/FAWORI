import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';
import '../widgets/fawori_logo.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenProducts;
  const HomeScreen({super.key, this.onOpenProducts});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _banner = 0;

  final List<_Category> _categories = const [
    _Category('brand_fawori', 'FAVORI', Color(0xFFE8A33D), Icons.format_paint_rounded, true),
    _Category('gifts', 'GIFTS', Color(0xFF3EC6C0), Icons.redeem_rounded, false),
    _Category('brand_isomat', 'isomat', Color(0xFFD93025), Icons.apartment_rounded, false),
    _Category('brand_cadence', 'CADENCE', Color(0xFFEDEDED), Icons.palette_rounded, false),
    _Category('brand_sibax', 'SIBAX', Color(0xFFC9A227), Icons.build_rounded, false),
    _Category('certifiedAgents', 'AGENTS', Color(0xFF4C8DF5), Icons.people_alt_rounded, false),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(s),
              const SizedBox(height: 12),
              _bannerView(),
              _dots(),
              const SizedBox(height: 20),
              _sectionTitle(s.tr('quickAccess')),
              _quickAccess(s),
              const SizedBox(height: 20),
              _grid(s),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppSettings s) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                          colors: [AppColors.orange, AppColors.teal]).createShader(r),
                  child: const Icon(Icons.waves_rounded, size: 30, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(s.tr('appName'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {},
            ),
          ],
        ),
      );

  Widget _bannerView() => SizedBox(
        height: 230,
        child: PageView.builder(
          itemCount: 4,
          onPageChanged: (i) => setState(() => _banner = i),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                    colors: [Color(0xFFEE6C2B), Color(0xFFF79A3E), Color(0xFFEE6C2B)]),
              ),
              child: const Center(child: FaworiLogo(size: 150)),
            ),
          ),
        ),
      );

  Widget _dots() => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: i == _banner ? AppColors.orange : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              )),
        ),
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      );

  Widget _quickAccess(AppSettings s) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(child: _quickBtn(s.tr('products'), Icons.inventory_2_rounded, AppColors.orange, widget.onOpenProducts)),
            const SizedBox(width: 12),
            Expanded(child: _quickBtn(s.tr('gifts'), Icons.redeem_rounded, AppColors.teal, widget.onOpenProducts)),
          ],
        ),
      );

  Widget _quickBtn(String t, IconData ic, Color c, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Expanded(
                child: Center(
                    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)))),
            Icon(ic, color: c, size: 26),
          ]),
        ),
      );

  Widget _grid(AppSettings s) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14,
            childAspectRatio: 0.85,
          ),
          itemCount: _categories.length,
          itemBuilder: (_, i) => _categoryCard(s, _categories[i]),
        ),
      );

  Widget _categoryCard(AppSettings s, _Category c) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: c.color.withAlpha(31),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: c.useLogo
                      ? const FaworiLogo(size: 80)
                      : Text(c.latin,
                          style: TextStyle(color: c.color, fontWeight: FontWeight.w800, fontSize: 18)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: Center(
                      child: Text(s.tr(c.trKey),
                          style: const TextStyle(fontWeight: FontWeight.w700)))),
              Icon(c.icon, color: Colors.grey.shade400, size: 20),
            ]),
          ],
        ),
      );
}

class _Category {
  final String trKey, latin;
  final Color color;
  final IconData icon;
  final bool useLogo;
  const _Category(this.trKey, this.latin, this.color, this.icon, this.useLogo);
}
