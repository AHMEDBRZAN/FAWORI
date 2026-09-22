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
import 'admin_users.dart';
import 'product_detail_screen.dart';

const String _kProxy = 'https://fawori.ahmdkaka1997.workers.dev/put';

String _dmy(String iso) {
  final p = iso.split('-');
  if (p.length == 3 && p[0].length == 4) return iso;
  if (p.length == 3 && p[2].length == 4) return '${p[2]}-${p[1]}-${p[0]}';
  return iso;
}

int _tsId(String id) {
  if (id.contains('_ret_')) return int.tryParse(id.split('_ret_').last) ?? 0;
  if (id.endsWith('_ret')) {
    return int.tryParse(id.substring(0, id.length - 4)) ?? 0;
  }
  return int.tryParse(id) ?? 0;
}

// ======================================================
// المحفظة (مستخدم)
// ======================================================

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  List<Invoice> _invoices = [];
  List<Map<String, dynamic>> _returns = [];
  int _lastVersion = -1;
  String _wFilter = 'all';
  bool _netOpen = false;

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
    final rets = await OrdersService.loadReturns();
    if (mounted) {
      setState(() {
        _invoices = invs;
        _returns = rets;
      });
    }
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
    final s = context.watch<AppSettings>();
    if (s.isAdmin || s.isImageAdmin) return const AdminPointsView();
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final mine = _invoices.where((i) => i.userId == s.user?.id).toList();

    final rows = <Map<String, dynamic>>[
      for (final i in mine.where((x) => x.type == 'sale'))
        {'kind': 'sale', 'inv': i},
      for (final i in mine.where((x) => x.type == 'return'))
        {'kind': 'return', 'inv': i},
      for (final r in _returns.where((x) => x['userId'] == s.user?.id))
        {'kind': 'return', 'ret': r},
    ];

    final filtered = _wFilter == 'sale'
        ? rows.where((r) => r['kind'] == 'sale').toList()
        : _wFilter == 'return'
            ? rows.where((r) => r['kind'] == 'return').toList()
            : rows;

    filtered.sort((a, b) => _tsOfRow(b).compareTo(_tsOfRow(a)));

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
                    child: Text('${filtered.length}',
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
              Row(
                children: [
                  Expanded(
                    child: Text(s.isArabic ? 'الفواتير' : 'Invoices',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                  _wChip(s.isArabic ? 'الكل' : 'All', 'all',
                      AppColors.orange),
                  _wChip(s.isArabic ? 'شراء' : 'Sale', 'sale',
                      AppColors.teal),
                  _wChip(s.isArabic ? 'مرتجع' : 'Return', 'return',
                      Colors.red),
                ],
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(s.isArabic ? 'لا توجد فواتير' : 'No invoices',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ),
                )
              else
                ...filtered.map((r) => _uniTile(s, r, dark)),
              if (rows.isNotEmpty) ...[
                const SizedBox(height: 16),
                _netCard(s, dark, rows),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ بطاقة صافي المشتريات: مجموع الشراء − مجموع المرتجع
  Widget _netCard(AppSettings s, bool dark, List<Map<String, dynamic>> rows) {
    int sumSales = 0;
    int sumReturns = 0;
    for (final r in rows) {
      if (r['kind'] == 'sale') {
        sumSales += (r['inv'] as Invoice).total.toInt();
      } else {
        final inv = r['inv'] as Invoice?;
        final ret = r['ret'] as Map<String, dynamic>?;
        sumReturns += inv != null
            ? inv.total.toInt().abs()
            : ((ret?['total'] as num?)?.toInt() ?? 0).abs();
      }
    }
    final net = sumSales - sumReturns;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? <Color>[const Color(0xFF1E1E28), const Color(0xFF26262E)]
              : <Color>[Colors.white, const Color(0xFFFFF8F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.orange.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(dark ? 60 : 15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_netOpen) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.teal.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shopping_bag_rounded,
                    color: AppColors.teal, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    s.isArabic ? 'مجموع الشراء' : 'Total purchases',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: dark ? Colors.white : AppColors.ink)),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(fmtThousands(sumSales),
                    style: const TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w900,
                        fontSize: 15)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
                color: Colors.grey.withAlpha(60), height: 1),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_return_rounded,
                    color: Colors.red, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    s.isArabic ? 'مجموع المرتجع' : 'Total returns',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: dark ? Colors.white : AppColors.ink)),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text('-${fmtThousands(sumReturns)}',
                    style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w900,
                        fontSize: 15)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
                color: Colors.grey.withAlpha(60), height: 1),
          ),
          ],
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFFF8C00), Color(0xFFF26B0F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withAlpha(80),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => setState(() => _netOpen = !_netOpen),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        s.isArabic ? 'صافي المشتريات' : 'Net purchases',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14)),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(fmtThousands(net),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18)),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _netOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _tsOfRow(Map<String, dynamic> row) {
    final inv = row['inv'] as Invoice?;
    final ret = row['ret'] as Map<String, dynamic>?;
    final id = inv != null ? inv.id : '${ret?['id'] ?? ''}';
    return _tsId(id);
  }

  Widget _wChip(String label, String value, Color c) {
    final active = _wFilter == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: InkWell(
        onTap: () => setState(() => _wFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(colors: <Color>[c, c.withAlpha(180)])
                : null,
            color: active ? null : c.withAlpha(18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.withAlpha(active ? 180 : 80)),
          ),
          child: Text(label,
              style: TextStyle(
                  color: active ? Colors.white : c,
                  fontWeight: FontWeight.w900,
                  fontSize: 11)),
        ),
      ),
    );
  }

  Widget _uniTile(AppSettings s, Map<String, dynamic> row, bool dark) {
    final isSale = row['kind'] == 'sale';
    final Invoice? inv = row['inv'] as Invoice?;
    final Map<String, dynamic>? ret = row['ret'] as Map<String, dynamic>?;
    final String date = inv != null ? inv.date : '${ret?['date'] ?? ''}';
    final String no = inv != null ? inv.no : '${ret?['no'] ?? ''}';
    final int total = inv != null
        ? inv.total.toInt()
        : -(((ret?['total'] as num?)?.toInt() ?? 0).abs());
    final int pts = inv != null
        ? inv.points.toInt()
        : -(((ret?['points'] as num?)?.toInt() ?? 0).abs());
    final c = isSale ? AppColors.teal : Colors.red;
    final bool neg = total < 0;

    return Pressable(
      onTap: () => inv != null
          ? _openDetails(s, inv)
          : _openReturnSheet(s, ret!, dark),
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
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(_dmy(date),
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    ),
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        fmtThousands(total),
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
                    child: Text(
                        isSale
                            ? (s.isArabic ? 'شراء' : 'Sale')
                            : (s.isArabic ? 'مرتجع' : 'Return'),
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
                      color: pts >= 0
                          ? AppColors.orange.withAlpha(30)
                          : Colors.red.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                          pts >= 0 ? '+$pts' : '-${pts.abs()}',
                          style: TextStyle(
                              color: pts >= 0 ? AppColors.orange : Colors.red,
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

  void _openReturnSheet(
      AppSettings s, Map<String, dynamic> r, bool dark) {
    final items = List<Map<String, dynamic>>.from((r['items'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map)));
    final no = '${r['no'] ?? ''}';
    final pNo = '${r['purchaseNo'] ?? ''}';
    final date = '${r['date'] ?? ''}';
    final total = ((r['total'] as num?)?.toInt() ?? 0).abs();
    final pts = ((r['points'] as num?)?.toInt() ?? 0).abs();
    final st = ((r['stored'] as num?)?.toInt() ?? 0).abs();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: dark ? const Color(0xFF1E1E28) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      const Color(0xFF9B59B6).withAlpha(dark ? 50 : 25),
                      const Color(0xFF9B59B6).withAlpha(dark ? 20 : 8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF9B59B6).withAlpha(70)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 15, color: Color(0xFF9B59B6)),
                    const SizedBox(width: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(_dmy(date),
                          style: TextStyle(
                              color:
                                  dark ? Colors.grey.shade200 : AppColors.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ),
                    const Spacer(),
                    const Icon(Icons.assignment_return_rounded,
                        size: 15, color: Color(0xFF9B59B6)),
                    const SizedBox(width: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(no.isEmpty ? '—' : no,
                          style: const TextStyle(
                              color: Color(0xFF9B59B6),
                              fontWeight: FontWeight.w900,
                              fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B59B6).withAlpha(dark ? 30 : 18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(s.isArabic ? 'فاتورة الشراء' : 'Purchase invoice',
                        style: TextStyle(
                            color: dark ? Colors.grey.shade300 : AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(pNo.isEmpty ? '—' : pNo,
                          style: const TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w900,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _miniTable(items, dark, s),
              const SizedBox(height: 12),
              _row(s.isArabic ? 'إجمالي المرتجع' : 'Return total',
                  '-${fmtThousands(total)}', Colors.red, big: true),
              _row(s.isArabic ? 'نقاط مخصومة' : 'Points deducted',
                  '-${fmtThousands(pts)}', Colors.red),
              _row(s.isArabic ? 'رصيد مخزن مخصوم' : 'Stored deducted',
                  '-${fmtThousands(st)}', Colors.red),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniTable(
      List<Map<String, dynamic>> rows, bool dark, AppSettings s) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF9B59B6).withAlpha(60)),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: const Color(0xFF9B59B6).withAlpha(dark ? 50 : 30),
            child: Row(
              children: [
                SizedBox(
                    width: 34,
                    child: Text(s.isArabic ? 'ت' : '#',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFF9B59B6),
                            fontWeight: FontWeight.w900,
                            fontSize: 13))),
                Expanded(
                    child: Text(s.isArabic ? 'اسم المادة' : 'Item',
                        style: const TextStyle(
                            color: Color(0xFF9B59B6),
                            fontWeight: FontWeight.w900,
                            fontSize: 13))),
                SizedBox(
                    width: 56,
                    child: Text(s.isArabic ? 'العدد' : 'Qty',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFF9B59B6),
                            fontWeight: FontWeight.w900,
                            fontSize: 13))),
              ],
            ),
          ),
          for (int i = 0; i < rows.length; i++)
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              color: i.isOdd
                  ? (dark
                      ? Colors.white.withAlpha(8)
                      : Colors.black.withAlpha(6))
                  : Colors.transparent,
              child: Row(
                children: [
                  SizedBox(
                      width: 34,
                      child: Text('${i + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: dark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w800))),
                  Expanded(
                      child: Text('${rows[i]['name']}',
                          style: TextStyle(
                              color: dark ? Colors.white : AppColors.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700))),
                  SizedBox(
                      width: 56,
                      child: Center(
                        child: Text('${rows[i]['qty']}',
                            style: const TextStyle(
                                color: Color(0xFF9B59B6),
                                fontWeight: FontWeight.w900,
                                fontSize: 12)),
                      )),
                ],
              ),
            ),
        ],
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
        initialChildSize: 0.75,
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
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.teal.withAlpha(dark ? 30 : 18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.teal.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 15, color: AppColors.teal),
                  const SizedBox(width: 6),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(_dmy(inv.date),
                        style: TextStyle(
                            color: dark ? Colors.grey.shade200 : AppColors.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                  ),
                  const Spacer(),
                  const Icon(Icons.receipt_long_outlined,
                      size: 15, color: AppColors.orange),
                  const SizedBox(width: 6),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(inv.no.isEmpty ? '—' : inv.no,
                        style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w900,
                            fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (inv.type == 'stored_point')
              _sourcesTable(inv, dark, s)
            else
              _itemsTable(inv, dark, s),
            const SizedBox(height: 14),
            if (inv.type == 'stored_point') ...[
              _row(s.isArabic ? 'نقاط هذه الفاتورة' : 'Points', '+1',
                  AppColors.teal),
              _row(s.isArabic ? 'الإجمالي' : 'Total',
                  fmtThousands(kPointUnit), const Color(0xFF9B59B6),
                  big: true),
            ] else ...[
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

  Widget _itemsTable(Invoice inv, bool dark, AppSettings s) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.orange.withAlpha(60)),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: AppColors.orange.withAlpha(dark ? 50 : 35),
            child: Row(
              children: [
                SizedBox(
                    width: 34,
                    child: Text(s.isArabic ? 'ت' : '#',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.orange,
                            fontSize: 13))),
                Expanded(
                    child: Text(s.isArabic ? 'اسم المادة' : 'Item',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.orange,
                            fontSize: 13))),
                SizedBox(
                    width: 56,
                    child: Text(s.isArabic ? 'العدد' : 'Qty',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.orange,
                            fontSize: 13))),
              ],
            ),
          ),
          for (int i = 0; i < inv.items.length; i++)
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              color: i.isOdd
                  ? (dark
                      ? Colors.white.withAlpha(8)
                      : Colors.black.withAlpha(6))
                  : Colors.transparent,
              child: Row(
                children: [
                  SizedBox(
                      width: 34,
                      child: Text('${i + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: dark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                              fontSize: 13))),
                  Expanded(
                      child: Text(inv.items[i].name,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: dark ? Colors.white : AppColors.ink,
                              fontSize: 13))),
                  SizedBox(
                      width: 56,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${inv.items[i].qty}',
                              style: const TextStyle(
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12)),
                        ),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sourcesTable(Invoice inv, bool dark, AppSettings s) {
    final srcs = _sourcesFor(inv);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF9B59B6).withAlpha(60)),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: const Color(0xFF9B59B6).withAlpha(dark ? 50 : 30),
            child: Row(
              children: [
                SizedBox(
                    width: 34,
                    child: Text(s.isArabic ? 'ت' : '#',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF9B59B6),
                            fontSize: 13))),
                Expanded(
                    child: Text(s.isArabic ? 'رقم الفاتورة' : 'Invoice No',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF9B59B6),
                            fontSize: 13))),
                SizedBox(
                    width: 80,
                    child: Text(s.isArabic ? 'المبلغ' : 'Amount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF9B59B6),
                            fontSize: 13))),
              ],
            ),
          ),
          for (int i = 0; i < srcs.length; i++)
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              color: i.isOdd
                  ? (dark
                      ? Colors.white.withAlpha(8)
                      : Colors.black.withAlpha(6))
                  : Colors.transparent,
              child: Row(
                children: [
                  SizedBox(
                      width: 34,
                      child: Text('${i + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: dark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                              fontSize: 13))),
                  Expanded(
                      child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                        '${srcs[i]['no']} • ${_dmy(srcs[i]['date'] as String)}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: dark ? Colors.white : AppColors.ink,
                            fontSize: 12)),
                  )),
                  SizedBox(
                      width: 80,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(fmtThousands(srcs[i]['amt'] as num),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Color(0xFF9B59B6),
                                fontWeight: FontWeight.w900,
                                fontSize: 12)),
                      )),
                ],
              ),
            ),
        ],
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
// 📊 صفحة النقاط والرصيد (للمدير)
// ======================================================

class AdminPointsView extends StatefulWidget {
  const AdminPointsView({super.key});
  @override
  State<AdminPointsView> createState() => _AdminPointsViewState();
}

class _AdminPointsViewState extends State<AdminPointsView> {
  List<User> _users = [];
  List<Invoice> _invoices = [];
  List<Map<String, dynamic>> _returns = [];
  bool _loading = true;
  String _q = '';
  User? _sel;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final u = await StoreService.loadUsers();
      final i = await StoreService.loadInvoices();
      final r = await OrdersService.loadReturns();
      if (mounted) {
        setState(() {
          _users = u.where((x) => x.role != 'guest').toList();
          _invoices = i;
          _returns = r;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _roleAr(String r) {
    if (r == 'agent') return 'وكيل';
    if (r == 'tech') return 'صباغ';
    if (r == 'admin') return 'مدير';
    return 'عميل';
  }

  List<Invoice> _salesOf(User u) {
    final list = _invoices
        .where((i) => i.userId == u.id && i.type == 'sale')
        .toList();
    list.sort((a, b) => _tsId(b.id).compareTo(_tsId(a.id)));
    return list;
  }

  List<Map<String, dynamic>> _returnsOf(User u) {
    final list = <Map<String, dynamic>>[
      ..._returns.where((r) => r['userId'] == u.id),
      for (final i in _invoices
          .where((x) => x.userId == u.id && x.type == 'return'))
        {
          'id': i.id,
          'legacy': true,
          'no': i.no,
          'date': i.date,
          'total': i.total,
          'points': i.points,
          'stored': i.stored,
          'purchaseNo': '',
          'items': i.items
              .map((it) => {'name': it.name, 'qty': it.qty})
              .toList(),
        },
    ];
    list.sort((a, b) =>
        _tsId('${b['id']}').compareTo(_tsId('${a['id']}')));
    return list;
  }

  int _pointsOf(User u) {
    int p = _invoices
        .where((i) => i.userId == u.id)
        .fold(0, (s, i) => s + i.points);
    p -= _returns
        .where((r) => r['userId'] == u.id)
        .fold(0, (s, r) => s + ((r['points'] as num?)?.toInt() ?? 0));
    return p;
  }

  int _storedOf(User u) {
    int s2 = _invoices
        .where((i) => i.userId == u.id)
        .fold(0, (s, i) => s + i.stored);
    s2 -= _returns
        .where((r) => r['userId'] == u.id)
        .fold(0, (s, r) => s + ((r['stored'] as num?)?.toInt() ?? 0));
    return s2;
  }

  bool _exactUser(User u, String q) =>
      u.name.trim().toLowerCase() == q || u.phone.trim() == q;

  bool _exactNo(String no, String q) => no.trim().toLowerCase() == q;

  List<User> _matchUsers(String q) => _users
      .where((u) =>
          u.name.toLowerCase().contains(q) || u.phone.contains(q))
      .toList();

  List<Invoice> _matchSales(String q) {
    final list = _invoices
        .where((i) => i.type == 'sale' && i.no.toLowerCase().contains(q))
        .toList();
    list.sort((a, b) => _tsId(b.id).compareTo(_tsId(a.id)));
    return list;
  }

  List<Map<String, dynamic>> _matchReturns(String q) {
    final list = <Map<String, dynamic>>[
      ..._returns.where((r) =>
          '${r['no']}'.toLowerCase().contains(q) ||
          '${r['purchaseNo']}'.toLowerCase().contains(q)),
      for (final i in _invoices.where((x) =>
          x.type == 'return' && x.no.toLowerCase().contains(q)))
        {
          'id': i.id,
          'legacy': true,
          'no': i.no,
          'date': i.date,
          'total': i.total,
          'points': i.points,
          'stored': i.stored,
          'purchaseNo': '',
          'items': i.items
              .map((it) => {'name': it.name, 'qty': it.qty})
              .toList(),
        },
    ];
    list.sort((a, b) =>
        _tsId('${b['id']}').compareTo(_tsId('${a['id']}')));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final q = _q.trim().toLowerCase();

    return Scaffold(
      backgroundColor:
          dark ? const Color(0xFF141419) : const Color(0xFFFFF8F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _sel != null
            ? Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.orange.withAlpha(dark ? 50 : 30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: AppColors.orange, size: 22),
                  onPressed: () => setState(() {
                        _sel = null;
                        _filter = 'all';
                      }),
                ),
              )
            : null,
        title: Text(
          _sel == null
              ? (s.isArabic ? 'النقاط والرصيد' : 'Points & Stored')
              : _sel!.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: dark ? Colors.white : AppColors.ink,
          ),
        ),
        actions: _sel == null
            ? [
                IconButton(
                  tooltip: s.isArabic ? 'إنشاء حساب' : 'Create account',
                  icon: const Icon(Icons.person_add_alt_1_rounded,
                      color: AppColors.teal),
                  onPressed: () async {
                    final created = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateAccountPage()));
                    if (created == true) {
                      await _load();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    '✅ تم إنشاء الحساب والسجل بنجاح')));
                      }
                    }
                  },
                ),
              ]
            : null,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.orange))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.orange,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _searchField(s, dark),
                  const SizedBox(height: 14),
                  if (_sel == null)
                    ..._usersSection(s, dark, q)
                  else
                    ..._userInvoicesSection(s, dark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _searchField(AppSettings s, bool dark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: dark
              ? <Color>[
                  const Color(0xFF1E1E28),
                  const Color(0xFF26262E),
                ]
              : <Color>[
                  Colors.white,
                  const Color(0xFFFFF8F1),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.orange.withAlpha(60), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withAlpha(25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        onChanged: (v) => setState(() => _q = v),
        style: TextStyle(
            color: dark ? Colors.white : AppColors.ink, fontSize: 15),
        decoration: InputDecoration(
          hintText: s.isArabic
              ? 'بحث ذكي: رقم فاتورة / اسم حساب / رقم هاتف'
              : 'Smart search: invoice No / name / phone',
          hintStyle: TextStyle(
              color: dark ? Colors.grey.shade500 : Colors.grey.shade400,
              fontSize: 13),
          prefixIcon: Container(
            margin: const EdgeInsetsDirectional.only(end: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[AppColors.orange, Color(0xFFF26B0F)],
              ),
              borderRadius: BorderRadiusDirectional.only(
                topEnd: Radius.circular(22),
                bottomEnd: Radius.circular(22),
              ),
            ),
            child: const Icon(Icons.search_rounded,
                color: Colors.white, size: 22),
          ),
          suffixIcon: _q.isNotEmpty
              ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.clear_rounded,
                        color: Colors.red, size: 18),
                  ),
                  onPressed: () => setState(() => _q = ''),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(User u, AppSettings s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  s.isArabic ? 'حذف نهائي' : 'Permanent delete',
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        content: Text(
            s.isArabic
                ? 'سيُحذف المستخدم "${u.name}" مع جميع فواتيره ومرتجعاته وطلباته. لا يمكن التراجع!'
                : 'User "${u.name}" will be deleted with all invoices, returns and orders. Cannot undo!',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.isArabic ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.isArabic ? 'حذف الكل' : 'Delete all'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await OrdersService.deleteUserAll(u.id);
      if (_sel?.id == u.id) _sel = null;
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(s.isArabic
                ? '🗑️ تم حذف ${u.name} وكل فواتيره'
                : 'Deleted ${u.name} and all invoices')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل: $e')));
      }
    }
  }

  Future<void> _confirmDeleteInvoice(Invoice i, AppSettings s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  s.isArabic ? 'حذف الفاتورة' : 'Delete invoice',
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        content: Text(
            s.isArabic
                ? 'ستُحذف الفاتورة رقم ${i.no.isEmpty ? i.id : i.no} مع مرتجعاتها، وتُخصم نقاطها ورصيدها من المستخدم. لا يمكن التراجع!'
                : 'Invoice ${i.no.isEmpty ? i.id : i.no} and its returns will be deleted. Cannot undo!',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.isArabic ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await OrdersService.deleteInvoice(i.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(s.isArabic
                ? '🗑️ تم حذف الفاتورة ومرتجعاتها'
                : 'Invoice and its returns deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل: $e')));
      }
    }
  }

  Future<void> _confirmDeleteReturn(
      Map<String, dynamic> r, AppSettings s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  s.isArabic ? 'حذف المرتجع' : 'Delete return',
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        content: Text(
            s.isArabic
                ? 'سيُحذف سجل المرتجع هذا نهائياً. لا يمكن التراجع!'
                : 'This return record will be deleted. Cannot undo!',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.isArabic ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      if (r['legacy'] == true) {
        await OrdersService.deleteInvoice('${r['id']}');
      } else {
        await OrdersService.deleteReturn('${r['id']}');
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                s.isArabic ? '🗑️ تم حذف المرتجع' : 'Return deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل: $e')));
      }
    }
  }

  List<Widget> _usersSection(AppSettings s, bool dark, String q) {
    if (q.isEmpty) {
      return [
        _sectionTitle(s.isArabic ? 'المسجلون' : 'Registered',
            Icons.people_alt_rounded, AppColors.teal),
        const SizedBox(height: 10),
        for (final u in _users) _userRow(u, s, dark, false),
      ];
    }
    final us = _matchUsers(q);
    final sa = _matchSales(q);
    final re = _matchReturns(q);
    return [
      _sectionTitle(s.isArabic ? 'نتائج البحث' : 'Search results',
          Icons.search_rounded, AppColors.orange),
      const SizedBox(height: 10),
      if (us.isEmpty && sa.isEmpty && re.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Center(
              child: Text(s.isArabic ? 'لا توجد نتائج' : 'No results',
                  style: TextStyle(color: Colors.grey.shade500))),
        ),
      for (final u in us) _userRow(u, s, dark, _exactUser(u, q)),
      if (sa.isNotEmpty) ...[
        const SizedBox(height: 14),
        _sectionTitle(s.isArabic ? 'فواتير شراء مطابقة' : 'Matched sales',
            Icons.shopping_bag_rounded, AppColors.teal),
        const SizedBox(height: 10),
        for (final i in sa) _saleRow(i, s, dark, _exactNo(i.no, q)),
      ],
      if (re.isNotEmpty) ...[
        const SizedBox(height: 14),
        _sectionTitle(s.isArabic ? 'مرتجعات مطابقة' : 'Matched returns',
            Icons.assignment_return_rounded, Colors.red),
        const SizedBox(height: 10),
        for (final r in re)
          _returnRow(r, s, dark, _exactNo('${r['no'] ?? ''}', q)),
      ],
    ];
  }

  Widget _sectionTitle(String title, IconData icon, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[c.withAlpha(30), c.withAlpha(8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: c, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w900, color: c)),
          ),
        ],
      ),
    );
  }

  Widget _userRow(User u, AppSettings s, bool dark, bool glow) {
    return _Glow(
      glow: glow,
      child: Pressable(
        onTap: () => setState(() {
              _sel = u;
              _filter = 'all';
            }),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: dark
                  ? <Color>[
                      const Color(0xFF1E1E28),
                      const Color(0xFF26262E),
                    ]
                  : <Color>[Colors.white, const Color(0xFFFFF8F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.orange.withAlpha(50)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(dark ? 60 : 12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[
                      Color(0xFFFF8C00),
                      Color(0xFFF26B0F),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                      u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: dark ? Colors.white : AppColors.ink)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_roleAr(u.role),
                              style: const TextStyle(
                                  color: AppColors.teal,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 6),
                        Text(u.phone,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          AppColors.teal.withAlpha(40),
                          AppColors.teal.withAlpha(15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text('${fmtThousands(_pointsOf(u))} ⭐',
                          style: const TextStyle(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w900,
                              fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(fmtThousands(_storedOf(u)),
                        style: TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w800,
                            fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: s.isArabic ? 'تعديل' : 'Edit',
                icon: const Icon(Icons.edit_rounded,
                    color: AppColors.teal, size: 20),
                onPressed: () async {
                  final done = await EditUserDialog.show(context, u);
                  if (done == true) {
                    await _load();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(s.isArabic
                              ? '✅ تم تحديث بيانات المستخدم'
                              : 'User updated')));
                    }
                  }
                },
              ),
              IconButton(
                tooltip: s.isArabic ? 'حذف' : 'Delete',
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red, size: 20),
                onPressed: () => _confirmDelete(u, s),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _userInvoicesSection(AppSettings s, bool dark) {
    final u = _sel!;
    final sales = _salesOf(u);
    final rets = _returnsOf(u);
    return [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[
              Color(0xFFFF8C00),
              Color(0xFFF26B0F),
              Color(0xFFE8A33C)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: <double>[0.0, 0.55, 1.0],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withAlpha(80),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(35),
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: Colors.white.withAlpha(60), width: 2),
              ),
              child: Center(
                child: Text(
                    u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('${_roleAr(u.role)} • ${u.phone}',
                      style: TextStyle(
                          color: Colors.white.withAlpha(220), fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text('${fmtThousands(_pointsOf(u))} ⭐',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20)),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(fmtThousands(_storedOf(u)),
                      style: TextStyle(
                          color: Colors.white.withAlpha(230),
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          _chip(s.isArabic ? 'الكل' : 'All', 'all', AppColors.orange),
          _chip(s.isArabic ? 'شراء' : 'Sale', 'sale', AppColors.teal),
          _chip(s.isArabic ? 'مرتجع' : 'Return', 'return', Colors.red),
        ],
      ),
      const SizedBox(height: 14),
      if (_filter != 'return') ...[
        _sectionTitle(s.isArabic ? 'فواتير الشراء' : 'Sale invoices',
            Icons.shopping_bag_rounded, AppColors.teal),
        const SizedBox(height: 10),
        if (sales.isEmpty)
          Text(s.isArabic ? 'لا توجد' : 'None',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12))
        else
          for (final i in sales) _saleRow(i, s, dark, false),
      ],
      if (_filter != 'sale') ...[
        const SizedBox(height: 14),
        _sectionTitle(s.isArabic ? 'المرتجعات' : 'Returns',
            Icons.assignment_return_rounded, Colors.red),
        const SizedBox(height: 10),
        if (rets.isEmpty)
          Text(s.isArabic ? 'لا توجد' : 'None',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12))
        else
          for (final r in rets) _returnRow(r, s, dark, false),
      ],
    ];
  }

  Widget _chip(String label, String value, Color c) {
    final active = _filter == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: InkWell(
        onTap: () => setState(() => _filter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    colors: <Color>[c, c.withAlpha(180)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: active ? null : c.withAlpha(18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.withAlpha(active ? 180 : 80)),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: c.withAlpha(50),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(label,
              style: TextStyle(
                  color: active ? Colors.white : c,
                  fontWeight: FontWeight.w900,
                  fontSize: 12)),
        ),
      ),
    );
  }

  Widget _saleRow(Invoice i, AppSettings s, bool dark, bool glow) {
    return _Glow(
      glow: glow,
      child: Pressable(
        onTap: () => _openSaleDetails(i, s, dark),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: dark
                  ? <Color>[
                      const Color(0xFF1E1E28),
                      const Color(0xFF26262E),
                    ]
                  : <Color>[Colors.white, const Color(0xFFFFF8F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.teal.withAlpha(50)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(dark ? 50 : 10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[AppColors.teal, Color(0xFF0AA87A)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withAlpha(40),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(s.isArabic ? 'شراء' : 'Sale',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(_dmy(i.date),
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 11)),
                    ),
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(fmtThousands(i.total),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: dark ? Colors.white : AppColors.ink)),
                    ),
                    if (i.no.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(i.no,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 10)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      AppColors.teal.withAlpha(60),
                      AppColors.teal.withAlpha(25),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.teal.withAlpha(120)),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text('+${i.points}',
                      style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 14,
                          fontWeight: FontWeight.w900)),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: InkWell(
                  onTap: () => _confirmDeleteInvoice(i, s),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _returnRow(
      Map<String, dynamic> r, AppSettings s, bool dark, bool glow) {
    final no = '${r['no'] ?? ''}';
    final total = ((r['total'] as num?)?.toInt() ?? 0).abs();
    final pts = ((r['points'] as num?)?.toInt() ?? 0).abs();
    final date = '${r['date'] ?? ''}';
    return _Glow(
      glow: glow,
      child: Pressable(
        onTap: () => _openReturnDetails(r, s, dark),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: dark
                  ? <Color>[
                      const Color(0xFF1E1E28),
                      const Color(0xFF26262E),
                    ]
                  : <Color>[Colors.white, const Color(0xFFFFF8F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withAlpha(50)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(dark ? 50 : 10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Colors.red, Color(0xFFB02A2A)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withAlpha(40),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(s.isArabic ? 'مرتجع' : 'Return',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(_dmy(date),
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 11)),
                    ),
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text('-${fmtThousands(total)}',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.red.shade300)),
                    ),
                    if (no.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(no,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 10)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Colors.red.withAlpha(60),
                      Colors.red.withAlpha(25),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withAlpha(120)),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text('-$pts',
                      style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w900)),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: InkWell(
                  onTap: () => _confirmDeleteReturn(r, s),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSaleDetails(Invoice inv, AppSettings s, bool dark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: dark ? const Color(0xFF1E1E28) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      AppColors.teal.withAlpha(dark ? 40 : 25),
                      AppColors.teal.withAlpha(dark ? 15 : 8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.teal.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 15, color: AppColors.teal),
                    const SizedBox(width: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(_dmy(inv.date),
                          style: TextStyle(
                              color:
                                  dark ? Colors.grey.shade200 : AppColors.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ),
                    const Spacer(),
                    const Icon(Icons.receipt_long_outlined,
                        size: 15, color: AppColors.orange),
                    const SizedBox(width: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(inv.no.isEmpty ? '—' : inv.no,
                          style: const TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w900,
                              fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sheetTable(
                  inv.items
                      .map((it) => {'name': it.name, 'qty': it.qty})
                      .toList(),
                  dark,
                  s),
              const SizedBox(height: 12),
              _sheetRow(s.isArabic ? 'الإجمالي' : 'Total',
                  fmtThousands(inv.total), AppColors.orange, dark,
                  big: true),
              _sheetRow(s.isArabic ? 'نقاط هذه الفاتورة' : 'Points',
                  '${inv.points >= 0 ? '+' : ''}${fmtThousands(inv.points)}',
                  inv.points >= 0 ? AppColors.teal : Colors.red, dark),
              _sheetRow(s.isArabic ? 'رصيد مخزن منها' : 'Stored',
                  fmtThousands(inv.stored), AppColors.teal, dark),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _openReturnDetails(
      Map<String, dynamic> r, AppSettings s, bool dark) {
    final items = List<Map<String, dynamic>>.from((r['items'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map)));
    final no = '${r['no'] ?? ''}';
    final pNo = '${r['purchaseNo'] ?? ''}';
    final date = '${r['date'] ?? ''}';
    final total = ((r['total'] as num?)?.toInt() ?? 0).abs();
    final pts = ((r['points'] as num?)?.toInt() ?? 0).abs();
    final st = ((r['stored'] as num?)?.toInt() ?? 0).abs();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: dark ? const Color(0xFF1E1E28) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      const Color(0xFF9B59B6).withAlpha(dark ? 50 : 25),
                      const Color(0xFF9B59B6).withAlpha(dark ? 20 : 8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF9B59B6).withAlpha(70)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 15, color: Color(0xFF9B59B6)),
                    const SizedBox(width: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(_dmy(date),
                          style: TextStyle(
                              color:
                                  dark ? Colors.grey.shade200 : AppColors.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ),
                    const Spacer(),
                    const Icon(Icons.assignment_return_rounded,
                        size: 15, color: Color(0xFF9B59B6)),
                    const SizedBox(width: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(no.isEmpty ? '—' : no,
                          style: const TextStyle(
                              color: Color(0xFF9B59B6),
                              fontWeight: FontWeight.w900,
                              fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B59B6).withAlpha(dark ? 30 : 18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(s.isArabic ? 'فاتورة الشراء' : 'Purchase invoice',
                        style: TextStyle(
                            color: dark ? Colors.grey.shade300 : AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(pNo.isEmpty ? '—' : pNo,
                          style: const TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w900,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sheetTable(items, dark, s),
              const SizedBox(height: 12),
              _sheetRow(s.isArabic ? 'إجمالي المرتجع' : 'Return total',
                  '-${fmtThousands(total)}', Colors.red, dark,
                  big: true),
              _sheetRow(s.isArabic ? 'نقاط مخصومة' : 'Points deducted',
                  '-${fmtThousands(pts)}', Colors.red, dark),
              _sheetRow(s.isArabic ? 'رصيد مخزن مخصوم' : 'Stored deducted',
                  '-${fmtThousands(st)}', Colors.red, dark),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetTable(
      List<Map<String, dynamic>> rows, bool dark, AppSettings s) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.orange.withAlpha(60)),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Color(0xFFFF8C00), Color(0xFFF26B0F)],
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                    width: 34,
                    child: Text(s.isArabic ? 'ت' : '#',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13))),
                Expanded(
                    child: Text(s.isArabic ? 'اسم المادة' : 'Item',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13))),
                SizedBox(
                    width: 56,
                    child: Text(s.isArabic ? 'العدد' : 'Qty',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13))),
              ],
            ),
          ),
          for (int i = 0; i < rows.length; i++)
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              color: i.isOdd
                  ? (dark
                      ? Colors.white.withAlpha(8)
                      : Colors.black.withAlpha(6))
                  : Colors.transparent,
              child: Row(
                children: [
                  SizedBox(
                      width: 34,
                      child: Text('${i + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: dark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w800))),
                  Expanded(
                      child: Text('${rows[i]['name']}',
                          style: TextStyle(
                              color: dark ? Colors.white : AppColors.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700))),
                  SizedBox(
                      width: 56,
                      child: Center(
                        child: Text('${rows[i]['qty']}',
                            style: const TextStyle(
                                color: AppColors.teal,
                                fontWeight: FontWeight.w900,
                                fontSize: 12)),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sheetRow(
      String label, String value, Color c, bool dark, {bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: big ? 15 : 13,
                  color: dark ? Colors.white : AppColors.ink)),
          const Spacer(),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(value,
                style: TextStyle(
                    color: c,
                    fontWeight: FontWeight.w900,
                    fontSize: big ? 18 : 14)),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatefulWidget {
  final bool glow;
  final Widget child;
  const _Glow({required this.glow, required this.child});
  @override
  State<_Glow> createState() => _GlowState();
}

class _GlowState extends State<_Glow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (widget.glow) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _Glow old) {
    super.didUpdateWidget(old);
    if (widget.glow && !_c.isAnimating) _c.repeat(reverse: true);
    if (!widget.glow && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.glow) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withAlpha(
                  (60 + 160 * _c.value).toInt().clamp(0, 255)),
              blurRadius: 20 + 20 * _c.value,
              spreadRadius: 2,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    if (s.isAdmin || s.isImageAdmin) return const AdminCodeView();
    return const _FavoritesView();
  }
}

class _FavoritesView extends StatelessWidget {
  const _FavoritesView();

  Future<void> _addToCart(BuildContext context, Product p,
      [int qty = 1]) async {
    final s = context.read<AppSettings>();
    final uid = s.user?.id ?? '';
    if (uid.isEmpty) return;
    final cart = await OrdersService.loadCart(uid);
    final exist = cart.where((c) => c.id == p.id).toList();
    if (exist.isNotEmpty) {
      exist.first.qty += qty;
    } else {
      cart.add(CartItem(
          id: p.id, name: p.name, image: '', brand: p.brand, qty: qty));
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
                                onAdd: (q) => _addToCart(context, p, q),
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
              'https://api.github.com/repos/AHMEDBRZAN/FAWORI/git/trees/main?recursive=1&t=${DateTime.now().millisecondsSinceEpoch}'))
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    children: [
                      const SizedBox(height: 100),
                      Center(
                          child: Text(
                        s.isArabic
                            ? 'فشل التحميل: $_error'
                            : 'Failed: $_error',
                        style: const TextStyle(color: Colors.red),
                      )),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.orange,
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
// 📝 محرر الكود + تعديل أجزاء متعددة مع فحص تلقائي
// ======================================================

class _Patch {
  final TextEditingController old = TextEditingController();
  final TextEditingController neu = TextEditingController();
  /// ✅ حالة الفحص: null = لم يُفحص، true = موجود، false = غير موجود
  bool? found;
  /// عدد مرات التواجد (إذا > 1 = تحذير)
  int count = 0;
  void dispose() {
    old.dispose();
    neu.dispose();
  }
}

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
        Uri.parse(_kProxy),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم نسخ الكل')));
    }
  }

  Future<void> _paste() async {
    final d = await Clipboard.getData('text/plain');
    if (d?.text != null && mounted) {
      setState(() => _ctrl.text = d!.text!);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم لصق المحتوى')));
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

  Future<void> _pasteInto(TextEditingController c, VoidCallback done) async {
    final d = await Clipboard.getData('text/plain');
    if (d?.text != null) {
      c.text = d!.text!;
      done();
    }
  }

  /// ✅ فحص جزء واحد: هل نصه القديم موجود في المحتوى الحالي؟
  void _checkPatch(_Patch p, String content, VoidCallback refresh) {
    final old = p.old.text;
    if (old.isEmpty) {
      p.found = null;
      p.count = 0;
    } else {
      p.count = _countOccurrences(content, old);
      p.found = p.count > 0;
    }
    refresh();
  }

  int _countOccurrences(String source, String target) {
    if (target.isEmpty) return 0;
    int n = 0;
    int i = 0;
    while (true) {
      final idx = source.indexOf(target, i);
      if (idx < 0) break;
      n++;
      i = idx + target.length;
    }
    return n;
  }

  /// ✅ نافذة تعديل أجزاء مع فحص تلقائي وعلامة ✓/✗ لكل جزء
  void _openPatchDialog() {
    final s = context.read<AppSettings>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final patches = <_Patch>[_Patch()];

    // ✅ فحص أولي للأجزاء الموجودة
    for (final p in patches) {
      _checkPatch(p, _ctrl.text, () {});
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          // ✅ حساب عدد الأجزاء الصحيحة (found == true && count == 1)
          final validCount =
              patches.where((p) => p.found == true && p.count == 1).length;
          final allValid = validCount == patches.length && patches.isNotEmpty;

          return Dialog(
            backgroundColor: dark ? const Color(0xFF1E1E28) : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.find_replace_rounded,
                            color: AppColors.teal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              s.isArabic
                                  ? 'تعديل أجزاء من الكود'
                                  : 'Patch code parts',
                              style: const TextStyle(
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16)),
                        ),
                        IconButton(
                          tooltip: s.isArabic ? 'إضافة جزء' : 'Add part',
                          icon: const Icon(Icons.add_circle_outline,
                              color: AppColors.orange),
                          onPressed: () => setSt(() {
                            final np = _Patch();
                            patches.add(np);
                            _checkPatch(np, _ctrl.text, () {});
                          }),
                        ),
                      ],
                    ),
                  ),
                  // ✅ شريط ملخص الفحص
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: allValid
                          ? Colors.green.withAlpha(dark ? 40 : 25)
                          : AppColors.orange.withAlpha(dark ? 40 : 25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: allValid
                              ? Colors.green.withAlpha(80)
                              : AppColors.orange.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          allValid
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          color: allValid ? Colors.green : AppColors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.isArabic
                                ? '$validCount/${patches.length} جزء جاهز${allValid ? ' ✓' : ''}'
                                : '$validCount/${patches.length} ready${allValid ? ' ✓' : ''}',
                            style: TextStyle(
                                color:
                                    allValid ? Colors.green : AppColors.orange,
                                fontWeight: FontWeight.w800,
                                fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: patches.length,
                      itemBuilder: (c, i) {
                        final p = patches[i];
                        final ok = p.found == true && p.count == 1;
                        final warn = p.found == true && p.count > 1;
                        final bad = p.found == false;
                        final borderColor = p.old.text.isEmpty
                            ? Colors.grey.withAlpha(60)
                            : ok
                                ? Colors.green
                                : warn
                                    ? AppColors.orange
                                    : bad
                                        ? Colors.red
                                        : Colors.grey.withAlpha(60);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: dark
                                ? const Color(0xFF26262E)
                                : const Color(0xFFFFFDF9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: borderColor.withAlpha(140), width: 1.5),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.orange.withAlpha(30),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('${i + 1}',
                                        style: const TextStyle(
                                            color: AppColors.orange,
                                            fontWeight: FontWeight.w900)),
                                  ),
                                  const SizedBox(width: 8),
                                  // ✅ مؤشر الفحص
                                  if (p.old.text.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: ok
                                            ? Colors.green.withAlpha(30)
                                            : warn
                                                ? AppColors.orange
                                                    .withAlpha(30)
                                                : bad
                                                    ? Colors.red
                                                        .withAlpha(30)
                                                    : Colors.grey
                                                        .withAlpha(30),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            ok
                                                ? Icons.check_circle_rounded
                                                : warn
                                                    ? Icons
                                                        .warning_amber_rounded
                                                    : bad
                                                        ? Icons
                                                            .cancel_rounded
                                                        : Icons.hourglass_empty,
                                            size: 14,
                                            color: ok
                                                ? Colors.green
                                                : warn
                                                    ? AppColors.orange
                                                    : bad
                                                        ? Colors.red
                                                        : Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            ok
                                                ? (s.isArabic
                                                    ? 'مطابق'
                                                    : 'Matched')
                                                : warn
                                                    ? '${p.count}× ${s.isArabic ? 'تطابق' : 'matches'}'
                                                    : bad
                                                        ? (s.isArabic
                                                            ? 'غير موجود'
                                                            : 'Not found')
                                                        : '...',
                                            style: TextStyle(
                                              color: ok
                                                  ? Colors.green
                                                  : warn
                                                      ? AppColors.orange
                                                      : bad
                                                          ? Colors.red
                                                          : Colors.grey,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const Spacer(),
                                  if (patches.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red, size: 18),
                                      onPressed: () => setSt(() {
                                        patches[i].dispose();
                                        patches.removeAt(i);
                                      }),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: p.old,
                                maxLines: null,
                                minLines: 2,
                                onChanged: (_) =>
                                    _checkPatch(p, _ctrl.text, () => setSt(() {})),
                                style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: dark
                                        ? Colors.grey.shade100
                                        : AppColors.ink),
                                decoration: InputDecoration(
                                  hintText: s.isArabic
                                      ? 'الكود القديم (المراد استبداله)...'
                                      : 'Old code to replace...',
                                  hintStyle: TextStyle(
                                      color: dark
                                          ? Colors.grey.shade500
                                          : Colors.grey.shade400,
                                      fontSize: 11),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip:
                                            s.isArabic ? 'لصق' : 'Paste',
                                        icon: const Icon(
                                            Icons.content_paste_rounded,
                                            size: 18,
                                            color: AppColors.teal),
                                        onPressed: () => _pasteInto(p.old,
                                            () {
                                          _checkPatch(p, _ctrl.text,
                                              () => setSt(() {}));
                                        }),
                                      ),
                                    ],
                                  ),
                                  filled: true,
                                  fillColor: dark
                                      ? const Color(0xFF1E1E28)
                                      : Colors.white,
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: p.neu,
                                maxLines: null,
                                minLines: 2,
                                style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: dark
                                        ? Colors.grey.shade100
                                        : AppColors.ink),
                                decoration: InputDecoration(
                                  hintText: s.isArabic
                                      ? 'الكود الجديد (البديل)...'
                                      : 'New replacement code...',
                                  hintStyle: TextStyle(
                                      color: dark
                                          ? Colors.grey.shade500
                                          : Colors.grey.shade400,
                                      fontSize: 11),
                                  suffixIcon: IconButton(
                                    tooltip: s.isArabic ? 'لصق' : 'Paste',
                                    icon: const Icon(
                                        Icons.content_paste_rounded,
                                        size: 18,
                                        color: AppColors.orange),
                                    onPressed: () => _pasteInto(
                                        p.neu, () => setSt(() {})),
                                  ),
                                  filled: true,
                                  fillColor: dark
                                      ? const Color(0xFF1E1E28)
                                      : Colors.white,
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(s.isArabic ? 'إلغاء' : 'Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    allValid ? AppColors.teal : Colors.grey,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            onPressed: allValid
                                ? () {
                                    String content = _ctrl.text;
                                    int applied = 0;
                                    for (final p in patches) {
                                      content = content.replaceAll(
                                          p.old.text, p.neu.text);
                                      applied++;
                                    }
                                    setState(() => _ctrl.text = content);
                                    Navigator.pop(ctx);
                                    for (final p in patches) {
                                      p.dispose();
                                    }
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(s.isArabic
                                                  ? '✅ طُبّق $applied جزء بنجاح'
                                                  : '✅ Applied $applied parts')));
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(
                                s.isArabic ? 'تطبيق الكل' : 'Apply all'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
            tooltip: s.isArabic ? 'تعديل أجزاء' : 'Patch parts',
            icon: const Icon(Icons.find_replace_rounded,
                color: AppColors.teal),
            onPressed: _loading ? null : _openPatchDialog,
          ),
          IconButton(
            tooltip: s.isArabic ? 'لصق' : 'Paste',
            icon: const Icon(Icons.content_paste_rounded,
                color: AppColors.teal),
            onPressed: _paste,
          ),
          IconButton(
            tooltip: s.isArabic ? 'نسخ الكل' : 'Copy all',
            icon: const Icon(Icons.content_copy_rounded,
                color: AppColors.orange),
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
                      fillColor: dark
                          ? const Color(0xFF1E1E28)
                          : const Color(0xFFFFFDF9),
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
