import 'dart:convert';
import 'package:flutter/material.dart';
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

const String _rawBase =
    'https://raw.githubusercontent.com/AHMEDBRZAN/FAWORI/main';
const String _proxy = 'https://fawori.ahmdkaka1997.workers.dev/put';

String _dmy(String iso) {
  try {
    final p = iso.split('-');
    return '${p[0]}-${p[1].padLeft(2, '0')}-${p[2].padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}

// ======================================================
// المحفظة (للمدير ← صفحة تسجيل المستخدمين)
// ======================================================

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  List<Invoice> _invoices = [];
  int _returnPool = 0;
  int _lastVersion = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = context.read<AppSettings>();
    if (s.isAdmin) return; // المدير لا يحتاج تحميل المحفظة
    final v = s.ordersVersion;
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
    if (mounted) {
      setState(() {
        _invoices = invs;
        _returnPool = OrdersService.returnPoolOf(invs, s.user?.id ?? '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    // ✅ المدير ← صفحة تسجيل المستخدمين بدل المحفظة
    if (s.isAdmin) return const _AdminRegister();
    return _walletBody(s);
  }

  // ================= واجهة المحفظة للمستخدم =================
  String _typeLabel(Invoice inv, bool ar) {
    if (inv.type == 'return') return ar ? 'مرتجع' : 'Return';
    if (inv.type == 'stored_point') return ar ? 'الرصيد المخزن' : 'Stored';
    if (inv.type == 'return_stored') {
      return ar ? 'الرصيد المخزن للمرتجع' : 'Return stored';
    }
    return ar ? 'شراء' : 'Sale';
  }

  Color _typeColor(Invoice inv) {
    if (inv.type == 'return') return Colors.red;
    if (inv.type == 'stored_point') return const Color(0xFF9B59B6);
    if (inv.type == 'return_stored') return const Color(0xFF7D3C98);
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

  List<Map<String, dynamic>> _returnSourcesFor(Invoice conv) {
    final k = int.tryParse(conv.id.split('_rsp_').last) ?? 0;
    final start = k * 125000.0;
    final end = start + 125000.0;
    double acc = 0;
    final out = <Map<String, dynamic>>[];
    for (final i in _invoices) {
      if (i.userId != conv.userId || i.type != 'return' || i.stored != 0) {
        continue;
      }
      final part = i.total.abs() % 125000;
      if (part <= 0) continue;
      final s0 = acc;
      final s1 = acc + part;
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

  Widget _sourcesTable(
      List<Map<String, dynamic>> srcs, bool dark, Color c, bool ar) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withAlpha(50)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(ar ? 'التاريخ' : 'Date',
                    style: TextStyle(
                        color:
                            dark ? Colors.grey.shade300 : Colors.grey.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
              Expanded(
                flex: 3,
                child: Text(ar ? 'رقم الفاتورة' : 'Invoice No',
                    style: TextStyle(
                        color:
                            dark ? Colors.grey.shade300 : Colors.grey.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
              Expanded(
                flex: 2,
                child: Text(ar ? 'المبلغ' : 'Amount',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        color:
                            dark ? Colors.grey.shade300 : Colors.grey.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          Divider(height: 12, color: c.withAlpha(60)),
          ...srcs.map((src) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(_dmy(src['date'] as String),
                          style: TextStyle(
                              color: dark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                              fontSize: 12)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(src['no'] as String,
                          style: TextStyle(
                              color: dark ? Colors.white : AppColors.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(fmtThousands(src['amt'] as num),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              color: c,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _walletBody(AppSettings s) {
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
                          child: Text(
                              '${s.isArabic ? 'رصيد مخزن' : 'Stored'}: ${fmtThousands(s.stored)}',
                              style: TextStyle(
                                  color: Colors.white.withAlpha(230),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Text(
                            '${s.isArabic ? 'متبقي' : 'Remaining'} ${fmtThousands(remaining)} ${s.isArabic ? 'للنقطة القادمة' : 'to next point'}',
                            style: TextStyle(
                                color: Colors.white.withAlpha(230),
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    if (_returnPool > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.assignment_return_rounded,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                                '${s.isArabic ? 'الرصيد المخزن للمرتجع' : 'Return stored'}: ${fmtThousands(_returnPool)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
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
                      Text(fmtThousands(s.stored),
                          style: const TextStyle(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w900,
                              fontSize: 16)),
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
    final num shownTotal = inv.type == 'stored_point'
        ? kPointUnit
        : (inv.type == 'return_stored' ? -kPointUnit : inv.total);
    return Pressable(
      onTap: () => _openDetails(s, inv),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E1E28) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withAlpha(60)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_typeLabel(inv, s.isArabic),
                      style: TextStyle(
                          color: c, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: inv.points >= 0
                        ? AppColors.orange.withAlpha(30)
                        : Colors.red.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                      '${inv.points >= 0 ? '+' : ''}${fmtThousands(inv.points)}',
                      style: TextStyle(
                          color:
                              inv.points >= 0 ? AppColors.orange : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(_dmy(inv.date),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const SizedBox(height: 4),
            Text(fmtThousands(shownTotal),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900)),
          ],
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
              _sourcesTable(_sourcesFor(inv), dark,
                  const Color(0xFF9B59B6), s.isArabic),
              const Divider(height: 24),
              _row(s.isArabic ? 'الإجمالي' : 'Total',
                  fmtThousands(kPointUnit), const Color(0xFF9B59B6),
                  big: true),
            ] else if (inv.type == 'return_stored') ...[
              _row(s.isArabic ? 'رقم الفاتورة' : 'Invoice No', inv.no,
                  AppColors.orange, big: true),
              _row(s.isArabic ? 'نقاط هذه الفاتورة' : 'Points', '-1',
                  Colors.red),
              _row(
                  s.isArabic
                      ? 'مخصوم من الرصيد المخزن'
                      : 'Deducted from stored',
                  fmtThousands(kPointUnit), const Color(0xFF7D3C98)),
              const SizedBox(height: 10),
              Text(s.isArabic ? 'تكوّن من مرتجعات:' : 'From returns:',
                  style: TextStyle(
                      color:
                          dark ? Colors.grey.shade300 : Colors.grey.shade700,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              _sourcesTable(_returnSourcesFor(inv), dark,
                  const Color(0xFF7D3C98), s.isArabic),
              const Divider(height: 24),
              _row(s.isArabic ? 'الإجمالي' : 'Total',
                  fmtThousands(-kPointUnit), const Color(0xFF7D3C98),
                  big: true),
            ] else if (inv.type == 'return') ...[
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
                            color: Colors.red.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: Colors.red.withAlpha(90)),
                          ),
                          child: Text('× ${it.qty}',
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 24),
              _row(s.isArabic ? 'الإجمالي المرتجع' : 'Returned total',
                  fmtThousands(inv.total), Colors.red, big: true),
              _row(s.isArabic ? 'نقاط مخصومة' : 'Points deducted',
                  '${inv.points <= 0 ? '' : '+'}${fmtThousands(inv.points)}',
                  Colors.red),
              _row(
                  s.isArabic
                      ? 'الرصيد المخزن للمرتجع'
                      : 'Return stored pool',
                  fmtThousands(inv.total.abs() % kPointUnit),
                  const Color(0xFF9B59B6)),
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
                  fmtThousands(inv.total), AppColors.orange, big: true),
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
// ✅ صفحة تسجيل المستخدمين (تظهر للمدير فقط بدل المحفظة)
// ======================================================

class _AdminRegister extends StatefulWidget {
  const _AdminRegister();
  @override
  State<_AdminRegister> createState() => _AdminRegisterState();
}

class _AdminRegisterState extends State<_AdminRegister> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _altPhone = TextEditingController();
  final _pass = TextEditingController();
  final _address = TextEditingController();
  final _customMarital = TextEditingController();
  final _customHousing = TextEditingController();
  final _customTransport = TextEditingController();

  String? _role;
  String? _marital;
  String? _housing;
  String? _transport;
  bool _showAltPhone = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _altPhone.dispose();
    _pass.dispose();
    _address.dispose();
    _customMarital.dispose();
    _customHousing.dispose();
    _customTransport.dispose();
    super.dispose();
  }

  /// ❗ نافذة التوضيح
  void _info(String title, String body) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dark ? const Color(0xFF1E1E28) : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.orange.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.priority_high_rounded,
                  color: AppColors.orange, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        content: Text(body,
            style: TextStyle(
                fontSize: 14,
                height: 1.7,
                color: dark ? Colors.grey.shade300 : Colors.grey.shade800)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('فهمت',
                style: TextStyle(
                    color: AppColors.teal, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _infoBtn(String title, String body) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.error_outline_rounded,
          color: AppColors.orange, size: 20),
      onPressed: () => _info(title, body),
    );
  }

  Widget _field(
    TextEditingController c, {
    required String label,
    String? hint,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    bool dark = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              if (suffix != null) suffix,
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            keyboardType: type,
            obscureText: obscure,
            style: TextStyle(
                color: dark ? Colors.white : AppColors.ink, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: dark ? Colors.grey.shade600 : Colors.grey.shade400,
                  fontSize: 13),
              filled: true,
              fillColor: dark ? const Color(0xFF26262E) : const Color(0xFFFFFDF9),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    Widget? suffix,
    bool dark = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              if (suffix != null) suffix,
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF26262E) : const Color(0xFFFFFDF9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: (dark ? Colors.white24 : Colors.black26)
                      .withAlpha(60)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: dark ? const Color(0xFF26262E) : Colors.white,
                style: TextStyle(
                    color: dark ? Colors.white : AppColors.ink, fontSize: 14),
                hint: const Text('اختر...'),
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final s = context.read<AppSettings>();
    // ✅ تحقق
    if (_role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ اختر نوع الحساب')));
      return;
    }
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ أدخل الاسم الرباعي')));
      return;
    }
    if (_phone.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ أدخل رقم هاتف صحيح')));
      return;
    }
    if (_pass.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚠️ كلمة السر أرقام فقط (4 أرقام على الأقل)')));
      return;
    }

    setState(() => _busy = true);
    try {
      // جلب المستخدمين الحاليين
      final r = await http
          .get(Uri.parse(
              '$_rawBase/assets/data/users.json?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 6));
      final List<dynamic> users =
          r.statusCode == 200 ? (jsonDecode(r.body) as List) : [];

      // منع تكرار رقم الهاتف
      for (final u in users) {
        if (u is Map && u['phone']?.toString() == _phone.text.trim()) {
          throw Exception('رقم الهاتف مسجل مسبقاً');
        }
      }

      final marital = _marital == 'أخرى'
          ? 'أخرى: ${_customMarital.text.trim()}'
          : (_marital ?? '');
      final housing = _housing == 'أخرى'
          ? 'أخرى: ${_customHousing.text.trim()}'
          : (_housing ?? '');
      final transport = _transport == 'أخرى'
          ? 'أخرى: ${_customTransport.text.trim()}'
          : (_transport ?? '');

      users.add({
        'id': 'u_${DateTime.now().millisecondsSinceEpoch}',
        'name': _name.text.trim(),
        'role': _role,
        'phone': _phone.text.trim(),
        'altPhone': _altPhone.text.trim(),
        'password': _pass.text.trim(),
        'address': _address.text.trim(),
        'marital': marital,
        'housing': housing,
        'transport': transport,
        'points': 0,
        'stored': 0,
        'registeredBy': 'admin',
        'registeredAt': DateTime.now().toString().substring(0, 10),
      });

      final pr = await http.post(
        Uri.parse(_proxy),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'path': 'assets/data/users.json',
          'content': base64Encode(utf8.encode(jsonEncode(users))),
        }),
      );
      if (pr.statusCode != 200 && pr.statusCode != 201) {
        throw Exception('فشل الرفع ${pr.statusCode}');
      }

      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.isArabic
              ? '✅ تم تسجيل المستخدم — يمكنه الدخول الآن'
              : '✅ User registered — can login now'),
          backgroundColor: const Color(0xFF0D9668),
        ));
        _name.clear();
        _phone.clear();
        _altPhone.clear();
        _pass.clear();
        _address.clear();
        _customMarital.clear();
        _customHousing.clear();
        _customTransport.clear();
        setState(() {
          _role = null;
          _marital = null;
          _housing = null;
          _transport = null;
          _showAltPhone = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final ar = s.isArabic;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person_add_alt_1_rounded,
                      color: AppColors.teal, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ar ? 'تسجيل المستخدمين' : 'User registration',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900)),
                      Text(
                        ar
                            ? 'يُسمح بالدخول فقط بعد تسجيل المدير'
                            : 'Login allowed only after admin registration',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1) نوع الحساب
            _dropdown(
              label: ar ? 'نوع الحساب' : 'Account type',
              value: _role,
              items: ar
                  ? ['وكيل', 'عميل', 'فني']
                  : ['Agent', 'Customer', 'Tech'],
              onChanged: (v) => setState(() {
                _role = ar
                    ? (v == 'وكيل'
                        ? 'agent'
                        : v == 'فني'
                            ? 'tech'
                            : 'customer')
                    : (v == 'Agent'
                        ? 'agent'
                        : v == 'Tech'
                            ? 'tech'
                            : 'customer');
              }),
              dark: dark,
            ),

            // 2) الاسم الرباعي
            _field(_name,
                label: ar ? 'الاسم الرباعي' : 'Full name (4 parts)',
                hint: ar ? 'مثال: حسين علي محمد حسن' : 'e.g. name name name name',
                dark: dark,
                suffix: _infoBtn(
                    ar ? 'الاسم الرباعي' : 'Full name',
                    ar
                        ? 'الاسم الرباعي لأجل التعرف بشكل كامل'
                        : 'Full four-part name for complete identification')),

            // 3) رقم الهاتف + بديل
            _field(_phone,
                label: ar ? 'رقم الهاتف' : 'Phone number',
                hint: '07xxxxxxxxx',
                type: TextInputType.phone,
                dark: dark,
                suffix: _infoBtn(
                  ar ? 'رقم الهاتف' : 'Phone',
                  ar
                      ? 'إضافة رقم هاتف ضروري جداً. هل يملك رقم بديل؟ اضغط (أضف رقم بديل) بالأسفل'
                      : 'Phone is required. Has an alternative? Use add below',
                )),
            if (_showAltPhone)
              _field(_altPhone,
                  label: ar ? 'رقم هاتف بديل' : 'Alternative phone',
                  hint: '07xxxxxxxxx',
                  type: TextInputType.phone,
                  dark: dark),
            Align(
              alignment: ar ? Alignment.centerLeft : Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _showAltPhone = !_showAltPhone),
                icon: Icon(
                    _showAltPhone
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    size: 18,
                    color: AppColors.teal),
                label: Text(
                    ar
                        ? (_showAltPhone ? 'إلغاء الرقم البديل' : 'أضف رقم بديل')
                        : (_showAltPhone ? 'Remove alt' : 'Add alt phone'),
                    style: const TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
              ),
            ),

            // 4) كلمة السر (أرقام فقط)
            _field(_pass,
                label: ar ? 'كلمة السر' : 'Password',
                hint: ar ? 'أرقام فقط مثال: 1234' : 'Digits only e.g. 1234',
                type: TextInputType.number,
                obscure: true,
                dark: dark),

            // 5) العنوان
            _field(_address,
                label: ar ? 'العنوان' : 'Address',
                hint: ar ? 'المحافظة / المدينة' : 'City / District',
                dark: dark,
                suffix: _infoBtn(
                    ar ? 'العنوان' : 'Address',
                    ar
                        ? 'شارع - نقطة دالة'
                        : 'Street - landmark')),

            // 6) الحالة الاجتماعية
            _dropdown(
              label: ar ? 'الحالة الاجتماعية' : 'Marital status',
              value: _marital,
              items: ar
                  ? ['متزوج', 'اعزب', 'مطلق', 'أخرى']
                  : ['Married', 'Single', 'Divorced', 'Other'],
              onChanged: (v) => setState(() => _marital = v),
              dark: dark,
              suffix: _infoBtn(
                  ar ? 'الحالة الاجتماعية' : 'Marital',
                  ar
                      ? 'الغرض منها مكافأة دفع تكاليف الزواج'
                      : 'Purpose: marriage costs reward'),
            ),
            if (_marital == 'أخرى' || _marital == 'Other')
              _field(_customMarital,
                  label: ar ? 'حدد الأخرى' : 'Specify other',
                  dark: dark),

            // 7) نوع دار السكن
            _dropdown(
              label: ar ? 'نوع دار السكن' : 'Housing type',
              value: _housing,
              items: ar ? ['ايجار', 'ملك', 'أخرى'] : ['Rent', 'Owned', 'Other'],
              onChanged: (v) => setState(() => _housing = v),
              dark: dark,
              suffix: _infoBtn(
                  ar ? 'نوع دار السكن' : 'Housing',
                  ar
                      ? 'الغرض منها مكافأة إهداء منزل'
                      : 'Purpose: house gift reward'),
            ),
            if (_housing == 'أخرى' || _housing == 'Other')
              _field(_customHousing,
                  label: ar ? 'حدد الأخرى' : 'Specify other',
                  dark: dark),

            // 8) وسائل النقل
            _dropdown(
              label: ar ? 'وسائل النقل' : 'Transport',
              value: _transport,
              items: ar
                  ? ['سيارة', 'دراجة', 'لا يوجد', 'أخرى']
                  : ['Car', 'Motorcycle', 'None', 'Other'],
              onChanged: (v) => setState(() => _transport = v),
              dark: dark,
            ),
            if (_transport == 'أخرى' || _transport == 'Other')
              _field(_customTransport,
                  label: ar ? 'حدد الأخرى' : 'Specify other',
                  dark: dark),

            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: <Color>[
                  Color(0xFF0D9668),
                  Color(0xFF0AA87A)
                ]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white),
                  onPressed: _busy ? null : _submit,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.person_add_alt_1_rounded, size: 20),
                  label: Text(
                      ar ? 'تسجيل المستخدم' : 'Register user',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                ar
                    ? 'لا يمكن للمستخدم الدخول إلا بعد اكتمال التسجيل من المدير'
                    : 'User can login only after admin completes registration',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
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
