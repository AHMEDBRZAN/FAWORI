import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/favorites.dart';
import '../data/sample_data.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.account_balance_wallet_rounded, size: 70, color: Colors.grey.shade600),
          const SizedBox(height: 12),
          Text(s.tr('wallet'), style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
          Text(s.tr('walletSoon'), style: const TextStyle(color: Colors.grey)),
        ]),
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
              child: Text(s.tr('noFavorites'), style: const TextStyle(color: Colors.grey)))
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
