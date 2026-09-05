import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/favorites.dart';
import '../core/store_service.dart';
import '../core/theme.dart';
import '../data/sample_data.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<List<Invoice>> _future = StoreService.loadInvoices();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<Invoice>>(
          future: _future,
          builder: (_, snap) {
            final all = snap.data ?? [];
            final mine = all.where((i) => i.userId == s.user?.id).toList();
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(s.tr('wallet'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFF26B0F), AppColors.orange]),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.attach_money_rounded,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.user?.name ?? '',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('${s.points}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const Spacer(),
                    Text(s.isArabic ? 'نقطة' : 'points',
                        style: const TextStyle(
                            color: Colors.white70, fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(height: 20),
                Text(s.isArabic ? 'الفواتير' : 'Invoices',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (mine.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Center(
                        child: Text(
                            s.isArabic
                                ? 'لا توجد فواتير بعد'
                                : 'No invoices yet',
                            style: const TextStyle(color: Colors.grey))),
                  )
                else
                  ...mine.map((inv) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(inv.date,
                                  style: TextStyle(
                                      color: Colors.grey.shade400, fontSize: 12)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withAlpha(40),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('+${inv.points}',
                                    style: const TextStyle(
                                        color: AppColors.orange,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            Text(
                                inv.items
                                    .map((e) => '${e.name} (${e.price.toStringAsFixed(0)})')
                                    .join('، '),
                                style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 8),
                            Text(
                                '${s.isArabic ? 'الإجمالي' : 'Total'}: ${inv.total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final favs = context.watch<Favorites>();
    final items = sampleProducts.where((p) => favs.contains(p.id)).toList();
    return Scaffold(
      appBar: AppBar(
          title: Text(s.tr('favorites')),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: items.isEmpty
          ? Center(
              child: Text(s.tr('noFavorites'),
                  style: const TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final p = items[i];
                return ListTile(
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  tileColor: Theme.of(context).colorScheme.surface,
                  title: Text(p.name),
                  subtitle:
                      Text(p.desc, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite_rounded,
                        color: Color(0xFFE5484D)),
                    onPressed: () => favs.toggle(p.id),
                  ),
                );
              },
            ),
    );
  }
}
