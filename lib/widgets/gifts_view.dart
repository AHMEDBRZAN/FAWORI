import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_settings.dart';
import '../core/gifts_service.dart';
import '../core/theme.dart';
import 'pressable.dart';

class GiftsView extends StatefulWidget {
  const GiftsView({super.key});
  @override
  State<GiftsView> createState() => _GiftsViewState();
}

class _GiftsViewState extends State<GiftsView> {
  late Future<List<Gift>> _future = GiftsService.load();
  String _cat = 'all';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return FutureBuilder<List<Gift>>(
      future: _future,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.orange));
        }
        final gifts = snap.data ?? [];
        final cats = [
          'all',
          ...gifts.map((g) => g.category).where((c) => c.isNotEmpty).toSet()
        ];
        final shown =
            _cat == 'all' ? gifts : gifts.where((g) => g.category == _cat).toList();
        return Column(
          children: [
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final c = cats[i];
                  final active = c == _cat;
                  return Pressable(
                    onTap: () => setState(() => _cat = c),
                    child: Container(
                      width: 110,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: active
                                ? AppColors.orange
                                : AppTheme.border(context),
                            width: active ? 1.5 : 1),
                      ),
                      child: Column(children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.orange.withAlpha(active ? 40 : 18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.redeem_rounded,
                                color: AppColors.orange, size: 26),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(c == 'all' ? s.tr('all') : c,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: shown.isEmpty
                  ? Center(
                      child: Text(s.tr('noProducts'),
                          style: const TextStyle(color: Colors.grey)))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.66,
                      ),
                      itemCount: shown.length,
                      itemBuilder: (_, i) => _giftCard(s, shown[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _giftCard(AppSettings s, Gift g) => Pressable(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 160,
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        g.image,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.redeem_rounded,
                                size: 60, color: AppColors.orange)),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: IconButton(
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.black26,
                          shape: const CircleBorder()),
                      icon: const Icon(Icons.favorite_border_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(g.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(g.desc,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${g.points}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppColors.orange),
                    child: const Icon(Icons.attach_money_rounded,
                        color: Colors.white, size: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
}
