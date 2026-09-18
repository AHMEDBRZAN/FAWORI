import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/favorites.dart';
import '../core/orders_service.dart';
import '../core/store_service.dart';
import '../core/theme.dart';
import '../data/sample_data.dart';
import '../widgets/pressable.dart';
import 'product_detail_screen.dart';

String _dmy(String iso) {
  try {
    final p = iso.split('-');
    return '${p[2].padLeft(2, '0')}-${p[1].padLeft(2, '0')}-${p[0]}';
  } catch (_) {
    return iso;
  }
}

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
  int _lastVersion = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final v = context.watch<AppSettings>().ordersVersion;
    if (v != _lastVersion) {
      _lastVersion = v;
      _load();
    }
  }

  Future<void> _load() async {
    final s = context.read<AppSettings>();
    try {
      final uid = s.user?.id ?? '';
      if (uid.isNotEmpty && !s.isGuest) {
        await OrdersService.convertStoredToPoints(uid);
      }
    } catch (_) {}
    try {
      await s.refreshUser();
    } catch (_) {}
    final invs = await StoreService.loadInvoices();
    if (mounted) setState(() => _invoices = invs);
  }

  String _typeLabel(Invoice inv, bool ar) {
    if (inv.type == 'return') return ar ? 'مرتجع' : 'Return';
    if (inv.type == 'stored_point') return ar ? 'الرصيد المخزن' : 'Stored';
    return ar ? 'شراء' : 'Sale';
  }

  Color _typeColor(Invoice inv) {
    if (inv.type == 'return') return Colors.red;
    if (inv.type == 'stored_point') return const Color(0xFF9B59B6);
    return AppColors.teal;
  }

  List<Map<String, dynamic>> _sourcesFor(Invoice conv) {
    final k = int.tryParse(conv.id.split('_sp_').last) ?? 0;
    final start = k * 125000.0;
    final end = start + 125000.0;
    double acc = 0;
    final out = <Map<String, dynamic>>[];
    for (final i in _invoices) {
      if (i.userId != conv.userId || i.type != 'sale' || i.stored <= 0) {
        continue;
      }
      final s0 = acc;
      final s1 = acc + i.stored;
      if (s1 > start && s0 < end) {
        final used = (s1 < end ? s1 : end) - (s0 > start ? s0 : start);
        final no = i.no.isNotEmpty
            ? i.no
            : '#${i.id.length > 6 ? i.id.substring(i.id.length - 6) : i.id}';
        out.add({'no': no, 'date': i.date, 'amt': used});
      }
      acc = s1;
      if (acc >= end) break;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings s = context.watch<AppSettings>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final mine = _invoices.where((i) => i.userId == s.user?.id).toList();
    final int storedMod = s.stored % kPointUnit;
    final int remaining = kPointUnit - storedMod;
    final double progress = storedMod / kPointUnit;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.teal,
          backgroundColor: dark ? const Color(0xFF1E1E28) : Colors.white,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
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
                        Text(fmtThousands(s.points),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                height: 1.1)),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                              s.isArabic ? 'نقطة' : 'points',
                              style: TextStyle(
                                  color: Colors.white.withAlpha(220),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
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
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                  '${s.isArabic ? 'رصيد مخزن' : 'Stored'}: ',
                                  style: TextStyle(
                                      color: Colors.white.withAlpha(230),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(fmtThousands(s.stored),
                                    style: TextStyle(
                                        color: Colors.white.withAlpha(230),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                        Text(
                            '${s.isArabic ? 'متبقي' : 'Remaining'} ${fmtThousands(remaining)} ${s.isArabic ? 'للنقطة القادمة' : 'to next point'}',
                            style: TextStyle(
                                color: Colors.white.withAlpha(230),
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(s.isArabic ? 'الفواتير' : 'Invoices',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900)),
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
                ...mine.reversed.map((inv) => _tile(s, inv, dark)),
              if (mine.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF1E1E28) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.teal.withAlpha(70)),
                  ),
                  child: Row(
                    children: [
                      Text(
                          s.isArabic
                              ? 'إجمالي الرصيد المخزن'
                              : 'Total stored',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: dark ? Colors.white : AppColors.ink)),
                      const Spacer(),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(fmtThousands(s.stored),
                            style: const TextStyle(
                                color: AppColors.teal,
                                fontWeight: FontWeight.w900,
                                fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(AppSettings s, Invoice inv, bool dark) {
    final c = _typeColor(inv);
    final num shownTotal =
        inv.type == 'stored_point' ? kPointUnit : inv.total;
    final bool neg = shownTotal < 0;
    return Pressable(
      onTap: () => _openDetails(s, inv),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E1E28) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withAlpha(60)),
        ),
        child: SizedBox(
          height: 62,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_dmy(inv.date),
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        fmtThousands(shownTotal),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: neg
                                ? Colors.red.shade300
                                : (dark ? Colors.white : AppColors.ink)),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_typeLabel(inv, s.isArabic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: c,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: inv.points >= 0
                          ? AppColors.orange.withAlpha(30)
                          : Colors.red.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                          '${inv.points >= 0 ? '+' : ''}${fmtThousands(inv.points)}',
                          style: TextStyle(
                              color: inv.points >= 0
                                  ? AppColors.orange
                                  : Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails(AppSettings s, Invoice inv) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: dark ? const Color(0xFF1E1E28) : Colors.white,
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
                    color: _typeColor(inv).withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_typeLabel(inv, s.isArabic),
                      style: TextStyle(
                          color: _typeColor(inv),
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_dmy(inv.date),
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (inv.type == 'stored_point') ...[
              _row(s.isArabic ? 'رقم الفاتورة' : 'Invoice No', inv.no,
                  AppColors.orange, big: true),
              _row(s.isArabic ? 'نقاط هذه الفاتورة' : 'Points', '+1',
                  AppColors.teal),
              const SizedBox(height: 10),
              Text(s.isArabic ? 'تكوّن من:' : 'From:',
                  style: TextStyle(
                      color:
                          dark ? Colors.grey.shade300 : Colors.grey.shade700,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              ..._sourcesFor(inv).map((src) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(
                                '${src['no']} • ${_dmy(src['date'] as String)}',
                                style: TextStyle(
                                    color: dark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700,
                                    fontSize: 13))),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(fmtThousands(src['amt'] as num),
                              style: const TextStyle(
                                  color: Color(0xFF9B59B6),
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 24),
              _row(s.isArabic ? 'الإجمالي' : 'Total',
                  fmtThousands(kPointUnit), const Color(0xFF9B59B6),
                  big: true),
            ] else ...[
              ...inv.items.map((it) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(it.name,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800))),
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
              _row(s.isArabic ? 'الإجمالي' : 'Total',
                  fmtThousands(inv.total), AppColors.orange,
                  big: true),
              _row(s.isArabic ? 'نقاط هذه الفاتورة' : 'Invoice points',
                  '${inv.points >= 0 ? '+' : ''}${fmtThousands(inv.points)}',
                  inv.points >= 0 ? AppColors.teal : Colors.red),
              _row(
                  s.isArabic
                      ? 'رصيد مخزن من هذه الفاتورة'
                      : 'Stored from this invoice',
                  fmtThousands(inv.stored), AppColors.teal),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color c, {bool big = false}) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: big ? 15 : 14,
                  color: dark ? Colors.white : AppColors.ink)),
          const Spacer(),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(value,
                style: TextStyle(
                    color: c,
                    fontWeight: FontWeight.w900,
                    fontSize: big ? 18 : 15)),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// المفضلة (مستخدم) / الإدارة (مدير)
// ======================================================

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    // ✅ المدير يرى شاشة الإدارة بدلاً من المفضلة
    if (s.isAdmin || s.isImageAdmin) return const AdminCodeView();
    return const _FavoritesView();
  }
}

class _FavoritesView extends StatelessWidget {
  const _FavoritesView();

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

// ======================================================
// 🛠️ شاشة الإدارة: ملفات الكود في المستودع
// ======================================================

class AdminCodeView extends StatefulWidget {
  const AdminCodeView({super.key});
  @override
  State<AdminCodeView> createState() => _AdminCodeViewState();
}

class _AdminCodeViewState extends State<AdminCodeView> {
  List<String> _files = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await http
          .get(Uri.parse(
              'https://api.github.com/repos/AHMEDBRZAN/FAWORI/git/trees/main?recursive=1'))
          .timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final j = jsonDecode(r.body);
      final tree = (j['tree'] as List<dynamic>? ?? []);
      final files = tree
          .where((e) =>
              e['type'] == 'blob' &&
              ((e['path'] as String).endsWith('.dart') ||
                  (e['path'] as String).endsWith('.yml')))
          .map((e) => e['path'] as String)
          .toList()
        ..sort();
      if (!mounted) return;
      setState(() {
        _files = files;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Map<String, List<String>> get _groups {
    final m = <String, List<String>>{};
    for (final p in _files) {
      final i = p.lastIndexOf('/');
      final dir = i <= 0 ? 'الجذر' : p.substring(0, i);
      m.putIfAbsent(dir, () => []).add(p);
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final groups = _groups;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(s.isArabic ? 'الإدارة' : 'Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.orange),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ListView(
                  children: [
                    const SizedBox(height: 100),
                    Center(
                        child: Text(
                      s.isArabic ? 'فشل التحميل: $_error' : 'Failed: $_error',
                      style: const TextStyle(color: Colors.red),
                    )),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final entry in groups.entries) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.folder_rounded,
                                  color: AppColors.orange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(entry.key,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14)),
                              ),
                              Text('${entry.value.length}',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        for (final f in entry.value)
                          Pressable(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        CodeEditorPage(path: f))),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: dark
                                    ? const Color(0xFF1E1E28)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.teal.withAlpha(60)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.description_outlined,
                                      color: AppColors.teal, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      f.split('/').last,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_left_rounded,
                                      color: Colors.grey, size: 20),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
    );
  }
}

// ======================================================
// 📝 محرر الكود
// ======================================================

class CodeEditorPage extends StatefulWidget {
  final String path;
  const CodeEditorPage({super.key, required this.path});
  @override
  State<CodeEditorPage> createState() => _CodeEditorPageState();
}

class _CodeEditorPageState extends State<CodeEditorPage> {
  final _ctrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await http
          .get(Uri.parse(
              'https://raw.githubusercontent.com/AHMEDBRZAN/FAWORI/main/${widget.path}?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      _ctrl.text = r.body;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل التحميل: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final r = await http.post(
        Uri.parse(kWriteProxy),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'path': widget.path,
          'content': base64Encode(utf8.encode(_ctrl.text)),
        }),
      );
      if (r.statusCode != 200 && r.statusCode != 201) {
        throw Exception('PUT ${r.statusCode}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ تم الحفظ والنشر — سيبدأ البناء تلقائياً')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل الحفظ: $e')));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _ctrl.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(' تم نسخ الكل')));
    }
  }

  Future<void> _paste() async {
    final d = await Clipboard.getData(ClipboardData.kTextPlain);
    if (d?.text != null && mounted) {
      setState(() => _ctrl.text = d!.text!);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📥 تم لصق المحتوى')));
    }
  }

  void _clear() {
    final s = context.read<AppSettings>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(s.isArabic ? 'مسح الكل' : 'Clear all'),
        content: Text(s.isArabic
            ? 'سيُحذف كل النص داخل المحرر (يمكنك اللصق بعده).'
            : 'All text in the editor will be cleared.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.isArabic ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _ctrl.text = '');
            },
            child: Text(s.isArabic ? 'مسح' : 'Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final name = widget.path.split('/').last;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(name, style: const TextStyle(fontSize: 15)),
        actions: [
          IconButton(
            tooltip: s.isArabic ? 'لصق' : 'Paste',
            icon: const Icon(Icons.content_paste_rounded,
                color: AppColors.teal),
            onPressed: _paste,
          ),
          IconButton(
            tooltip: s.isArabic ? 'نسخ الكل' : 'Copy all',
            icon:
                const Icon(Icons.content_copy_rounded, color: AppColors.orange),
            onPressed: _copy,
          ),
          IconButton(
            tooltip: s.isArabic ? 'مسح الكل' : 'Clear all',
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
            onPressed: _clear,
          ),
          IconButton(
            tooltip: s.isArabic ? 'حفظ ونشر' : 'Save & deploy',
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.teal))
                : const Icon(Icons.cloud_upload_rounded,
                    color: AppColors.teal),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: SingleChildScrollView(
                  child: TextField(
                    controller: _ctrl,
                    maxLines: null,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.5,
                      color: dark ? Colors.grey.shade100 : AppColors.ink,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor:
                          dark ? const Color(0xFF1E1E28) : const Color(0xFFFFFDF9),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
