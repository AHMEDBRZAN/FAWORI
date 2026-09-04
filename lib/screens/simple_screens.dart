import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/favorites.dart';
import '../data/sample_data.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.account_balance_wallet_rounded, size: 70, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            Text('المحفظة', style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
            const Text('هذه الصفحة نبنيها حسب شرحك لاحقاً', style: TextStyle(color: Colors.grey)),
          ]),
        ),
      );
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final favs = context.watch<Favorites>();
    final items = sampleProducts.where((p) => favs.contains(p.id)).toList();
    return Scaffold(
      appBar: AppBar(
          title: const Text('المفضلة'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: items.isEmpty
          ? const Center(
              child: Text('لا توجد منتجات في المفضلة بعد', style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final p = items[i];
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  tileColor: Theme.of(context).colorScheme.surface,
                  title: Text(p.name),
                  subtitle: Text(p.desc, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite_rounded, color: Color(0xFFE5484D)),
                    onPressed: () => favs.toggle(p.id),
                  ),
                );
              },
            ),
    );
  }
}
