import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/favorites.dart';
import '../core/orders_service.dart';
import '../core/store_service.dart';
import '../core/theme.dart';
import '../data/sample_data.dart';
import '../widgets/pressable.dart';
import 'product_detail_screen.dart';

// ======================================================
// المحفظة
// ======================================================

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  List<Invoice> _invoices = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await context.read<AppSettings>().refreshUser();
    } catch (_) {}
    final invs = await StoreService.loadInvoices();
    if (mounted) {
      setState(() {
        _invoices = invs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings s = context.watch<AppSettings>();
    final mine = _invoices.where((i) => i.userId == s.user?.id).toList();
    final int storedMod = s.stored % kPointUnit;
    final int remaining = kPointUnit - storedMod;
    final double progress = storedMod / kPointUnit;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.teal,
          backgroundColor: Theme.of(context).colorScheme.surface,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.isArabic ? 'المحفظة' : 'Wallet',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${mine.length}',
                        style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFFF26B0F), Color(0xFFE8A33C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.orange.withAlpha(60),
                        blurRadius: 18,
                        offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.user?.name ?? (s.isArabic ? 'ضيف' : 'Guest'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.monetization_on_rounded,
                              color: Colors.white, size: 26),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          fmtThousands(s.points),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              height: 1.1),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            s.isArabic ? 'نقطة' : 'points',
                            style: TextStyle(
                                color: Colors.white.withAlpha(220),
                                fontSize: 14,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.white.withAlpha(60),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${s.isArabic ? 'رصيد مخزن' : 'Stored'}: ${fmtThousands(s.stored)}',
                            style: TextStyle(
                                color: Colors.white.withAlpha(230),
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '${s.isArabic ? 'متبقي' : 'Remaining'} ${fmtThousands(remaining)} ${s.isArabic ? 'للنقطة القادمة' : 'to next point'}',
                          style: TextStyle(
                              color: Colors.white.withAlpha(230),
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                s.isArabic ? 'الفواتير' : 'Invoices',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              if (mine.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(s.isArabic ? 'لا توجد فواتير' : 'No invoices',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ),
                )
              else
                ...mine.reversed.map((inv) => _tile(s, inv)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(AppSettings s, Invoice inv) {
    final bool isReturn = inv.type == 'return';
    final Color c = isReturn ? const Color(0xFFD63C3C) : AppColors.teal;
    return Pressable(
      onTap: () => _openDetails(s, inv),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: c.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isReturn
                    ? (s.isArabic ? 'مرتجع' : 'Return')
                    : (s.isArabic ? 'شراء' : 'Sale'),
                style: TextStyle(
                    color: c, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.date,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(fmtThousands(inv.total),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${inv.items.length} ${s.isArabic ? 'مادة' : 'items'}',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11)),
                const SizedBox(height: 6),
                if (!isReturn)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('+${fmtThousands(inv.points)}',
                        style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteBox(String note) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orange.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text(note,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  void _openDetails(AppSettings s, Invoice inv) {
    final bool isReturn = inv.type == 'return';
    final Color c = isReturn ? const Color(0xFFD63C3C) : AppColors.teal;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                      isReturn
                          ? (s.isArabic ? 'مرتجع' : 'Return')
                          : (s.isArabic ? 'شراء' : 'Sale'),
                      style: TextStyle(
                          color: c,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(inv.date,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13)),
                ),
                Text(
                    '#${inv.id.length > 6 ? inv.id.substring(inv.id.length - 6) : inv.id}',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            ...inv.items.map((it) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(it.name,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.orange.withAlpha(90)),
                        ),
                        child: Text('× ${it.qty}',
                            style: const TextStyle(
                                color: AppColors.orange,
                                fontSize: 14,
                                fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                )),
            const Divider(height: 24),
            if (isReturn) ...[
              _row(s.isArabic ? 'قيمة المرتجع' : 'Return value',
                  fmtThousands(inv.total), const Color(0xFFD63C3C),
                  big: true),
              _row(s.isArabic ? 'رقم فاتورة المرتجع' : 'Return No', inv.no,
                  const Color(0xFFD63C3C)),
            ] else ...[
              _row(s.isArabic ? 'الإجمالي' : 'Total',
                  fmtThousands(inv.total), AppColors.orange, big: true),
              _row(s.isArabic ? 'نقاط هذه الفاتورة' : 'Invoice points',
                  '+${fmtThousands(inv.points)}', AppColors.teal),
              _row(
                  s.isArabic
                      ? 'رصيد مخزن من هذه الفاتورة'
                      : 'Stored from this invoice',
                  fmtThousands(inv.stored), AppColors.teal),
            ],
            if (inv.note.isNotEmpty) _noteBox(inv.note),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color c, {bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: big ? 15 : 14)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: c,
                  fontWeight: FontWeight.w900,
                  fontSize: big ? 18 : 15)),
        ],
      ),
    );
  }
}

// ======================================================
// المفضلة
// ======================================================

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _addToCart(BuildContext context, Product p) async {
    final s = context.read<AppSettings>();
    final uid = s.user?.id ?? '';
    if (uid.isEmpty) return;
    final cart = await OrdersService.loadCart(uid);
    final exist = cart.where((c) => c.id == p.id).toList();
    if (exist.isNotEmpty) {
      exist.first.qty++;
    } else {
      cart.add(CartItem(id: p.id, name: p.name, image: '', brand: p.brand));
    }
    await OrdersService.saveCart(uid, cart);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.isArabic ? '✅ أُضيف إلى السلة' : 'Added to cart')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings s = context.watch<AppSettings>();
    final favs = context.watch<Favorites>();
    final list = sampleData.where((p) => favs.contains(p.id)).toList();
    final bool canBuy = s.user != null && s.user!.role != 'guest';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(s.isArabic ? 'المفضلة' : 'Favorites'),
      ),
      body: list.isEmpty
          ? Center(
              child: Text(s.isArabic ? 'لا توجد مفضلات' : 'No favorites',
                  style: TextStyle(color: Colors.grey.shade500)))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final p = list[i];
                return Pressable(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                                product: p,
                                canBuy: canBuy,
                                onAdd: () => _addToCart(context, p),
                              ))),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          AppColors.orange.withAlpha(25),
                          Theme.of(context).colorScheme.surface
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: AppColors.orange.withAlpha(60)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: Icon(Icons.format_paint_rounded,
                                size: 46, color: AppColors.orange),
                          ),
                        ),
                        Text(p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(p.brand,
                              style: const TextStyle(
                                  color: AppColors.teal,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
