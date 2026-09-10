import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/favorites.dart';
import '../core/store_service.dart';
import '../core/theme.dart';
import '../data/sample_data.dart';
import '../widgets/pressable.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with WidgetsBindingObserver {
  static const int unit = 125000;
  static const List<String> _bucketOrder = [
    'today',
    'day1',
    'week',
    'month1',
    'month2',
    'older'
  ];

  late Future<List<Invoice>> _future = StoreService.loadInvoices();
  bool _refreshing = false;
  String _sig = '';
  String? _bucket;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh(silent: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh(silent: true);
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_refreshing || !mounted) return;
    setState(() => _refreshing = true);
    final s = context.read<AppSettings>();
    await s.refreshUser();
    final invs = await StoreService.loadInvoices();
    final mine = invs.where((i) => i.userId == s.user?.id).toList();
    final sig =
        '${s.points}|${s.stored}|${mine.length}|${mine.fold<int>(0, (a, b) => a + b.points)}';
    final changed = sig != _sig;
    if (!mounted) return;
    setState(() {
      _sig = sig;
      _future = Future.value(invs);
      _refreshing = false;
    });
    if (!silent || changed) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(changed
              ? 'تم جلب تحديثات جديدة ✅'
              : 'المحفظة محدّثة — لا تغييرات')));
    }
  }

  String _fmt(num n) {
    final s = n.toStringAsFixed(0);
    final out = StringBuffer();
    int c = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      out.write(s[i]);
      c++;
      if (c % 3 == 0 && i != 0) out.write(',');
    }
    return out.toString().split('').reversed.join();
  }

  int _days(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return 9999;
    final now = DateTime.now();
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(d.year, d.month, d.day);
    return a.difference(b).inDays;
  }

  String _bucketOf(int days) {
    if (days <= 0) return 'today';
    if (days == 1) return 'day1';
    if (days <= 7) return 'week';
    if (days <= 30) return 'month1';
    if (days <= 60) return 'month2';
    return 'older';
  }

  String _bucketLabel(String key, bool ar) {
    switch (key) {
      case 'today':
        return ar ? 'اليوم' : 'Today';
      case 'day1':
        return ar ? 'منذ يوم' : '1 day';
      case 'week':
        return ar ? 'منذ اسبوع' : '1 week';
      case 'month1':
        return ar ? 'منذ شهر' : '1 month';
      case 'month2':
        return ar ? 'منذ شهرين' : '2 months';
      default:
        return ar ? 'أقدم' : 'Older';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final u = s.user;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<Invoice>>(
          future: _future,
          builder: (_, snap) {
            final mine =
                (snap.data ?? []).where((i) => i.userId == u?.id).toList();
            final present = _bucketOrder
                .where((k) => mine.any((i) => _bucketOf(_days(i.date)) == k))
                .toList();
            final selected = (_bucket != null && present.contains(_bucket))
                ? _bucket!
                : (present.isNotEmpty ? present.first : '');
            final shown = mine
                .where((i) => _bucketOf(_days(i.date)) == selected)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(children: [
                  Text(s.tr('wallet'),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.orange.withAlpha(40),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('${mine.length}',
                        style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  Pressable(
                    onTap: () => _refresh(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.teal.withAlpha(90)),
                      ),
                      child: _refreshing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.teal))
                          : const Icon(Icons.refresh_rounded,
                              color: AppColors.teal, size: 18),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _pointsCard(s, u),
                const SizedBox(height: 24),
                Row(children: [
                  Text(s.isArabic ? 'الفواتير' : 'Invoices',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                ]),
                const SizedBox(height: 12),
                if (present.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Center(
                        child: Text(
                            s.isArabic ? 'لا توجد فواتير بعد' : 'No invoices yet',
                            style: const TextStyle(color: Colors.grey))),
                  )
                else ...[
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: present.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => _chip(
                          present[i],
                          mine
                              .where((x) =>
                                  _bucketOf(_days(x.date)) == present[i])
                              .length,
                          present[i] == selected,
                          s),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...shown.map((inv) => _tile(s, inv)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _chip(String key, int count, bool active, AppSettings s) => Pressable(
        onTap: () => setState(() => _bucket = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppColors.orange
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active ? Colors.transparent : AppTheme.border(context)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_bucketLabel(key, s.isArabic),
                style: TextStyle(
                    color: active ? Colors.black : AppTheme.text(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: active
                      ? Colors.black.withAlpha(30)
                      : AppColors.orange.withAlpha(40),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: active ? Colors.black : AppColors.orange)),
            ),
          ]),
        ),
      );

  Widget _pointsCard(AppSettings s, User? u) {
    final stored = u?.stored ?? 0;
    final remaining = unit - stored;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFF26B0F), AppColors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.orange.withAlpha(70),
              blurRadius: 24,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration:
                BoxDecoration(color: Colors.white.withAlpha(50), shape: BoxShape.circle),
            child:
                const Icon(Icons.attach_money_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u?.name ?? '',
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${u?.points ?? 0}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
            ]),
          ),
          Text(s.isArabic ? 'نقطة' : 'points',
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: stored / unit,
            minHeight: 8,
            backgroundColor: Colors.white.withAlpha(60),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Text(s.isArabic ? 'رصيد مخزن: ${_fmt(stored)}' : 'Stored: ${_fmt(stored)}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(
              s.isArabic
                  ? 'متبقي ${_fmt(remaining)} للنقطة القادمة'
                  : '${_fmt(remaining)} to next point',
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _tile(AppSettings s, Invoice inv) {
    final isRet = inv.type == 'return' || inv.points < 0;
    return Pressable(
      onTap: () => _openDetails(s, inv),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Column(children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: isRet ? Colors.red.withAlpha(35) : AppColors.teal.withAlpha(35),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                  isRet
                      ? (s.isArabic ? 'مرتجع' : 'Return')
                      : (s.isArabic ? 'شراء' : 'Purchase'),
                  style: TextStyle(
                      color: isRet ? Colors.red.shade300 : AppColors.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            Text(inv.date,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: isRet
                      ? Colors.red.withAlpha(35)
                      : AppColors.orange.withAlpha(40),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(inv.points < 0 ? '${inv.points}' : '+${inv.points}',
                  style: TextStyle(
                      color: isRet ? Colors.red.shade300 : AppColors.orange,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Text('${inv.items.length} ${s.isArabic ? 'مادة' : 'items'}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            const Spacer(),
            Text(_fmt(inv.total),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ]),
        ]),
      ),
    );
  }

  void _openDetails(AppSettings s, Invoice inv) {
    final isRet = inv.type == 'return' || inv.points < 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppTheme.border(context)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.grey.shade600, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: isRet
                        ? Colors.red.withAlpha(35)
                        : AppColors.teal.withAlpha(35),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(
                    isRet
                        ? (s.isArabic ? 'مرتجع' : 'Return')
                        : (s.isArabic ? 'شراء' : 'Purchase'),
                    style: TextStyle(
                        color: isRet ? Colors.red.shade300 : AppColors.teal,
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Text(inv.date,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              const Spacer(),
              Text(
                  inv.no.isNotEmpty
                      ? (s.isArabic ? 'فاتورة رقم ${inv.no}' : 'Invoice #${inv.no}')
                      : '#${inv.id.length > 6 ? inv.id.substring(inv.id.length - 6) : inv.id}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ]),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: inv.items.length,
                separatorBuilder: (_, __) => const Divider(height: 10),
                itemBuilder: (_, i) {
                  final it = inv.items[i];
                  return Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('${it.qty} × ${_fmt(it.price)}',
                                style: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 11)),
                          ]),
                    ),
                    Text(_fmt(it.price * it.qty),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13)),
                  ]);
                },
              ),
            ),
            const Divider(height: 18),
            Row(children: [
              Text(s.isArabic ? 'الإجمالي' : 'Total',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(_fmt(inv.total),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: AppColors.orange)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Text(s.isArabic ? 'نقاط هذه الفاتورة' : 'Invoice points',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              Text(inv.points < 0 ? '${inv.points}' : '+${inv.points}',
                  style: TextStyle(
                      color: inv.points < 0 ? Colors.red.shade300 : AppColors.teal,
                      fontWeight: FontWeight.w900,
                      fontSize: 15)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Text(
                  s.isArabic
                      ? 'رصيد مخزن من هذه الفاتورة'
                      : 'Stored from this invoice',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              Text(_fmt(inv.stored),
                  style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w900,
                      fontSize: 15)),
            ]),
            const SizedBox(height: 14),
          ],
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
