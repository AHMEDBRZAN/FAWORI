import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/orders_service.dart';
import '../core/theme.dart';
import '../widgets/pressable.dart';

/// ✅ تاريخ بصيغة يوم-شهر-سنة مع أصفار: 14-09-2026
String dmy(String iso) {
  try {
    final p = iso.split('-');
    final day = p[2].padLeft(2, '0');
    final month = p[1].padLeft(2, '0');
    final year = p[0];
    return '$year-$month-$day';
  } catch (_) {
    return iso;
  }
}

/// ✅ وقت بصيغة 12 ساعة مع ص/م: 9:15 ص
String time12(String idMillis) {
  try {
    final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(idMillis));
    int h = dt.hour % 12;
    if (h == 0) h = 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'ص' : 'م';
    return '$h:$m $period';
  } catch (_) {
    return '';
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Order>> _future = OrdersService.loadOrders();
  TabController? _tabCtrl;
  String _filter = 'pending';

  // ✅ مؤقت التحديث التلقائي كل 30 ثانية
  Timer? _pollTimer;
  int _lastPendingCount = -1;
  bool _isRefreshing = false;

  // ✅ نغمة WAV مخزنة للاستخدام المتكرر
  String? _beepUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final s = context.read<AppSettings>();
        final isAdmin = s.isAdmin || s.isImageAdmin;
        if (isAdmin) {
          _tabCtrl = TabController(length: 4, vsync: this);
          _tabCtrl!.addListener(() {
            if (!_tabCtrl!.indexIsChanging) {
              setState(() {
                switch (_tabCtrl!.index) {
                  case 0:
                    _filter = 'pending';
                    break;
                  case 1:
                    _filter = 'all';
                    break;
                  case 2:
                    _filter = 'accepted';
                    break;
                  case 3:
                    _filter = 'rejected';
                    break;
                }
              });
            }
          });
        }
        setState(() {
          _future = OrdersService.loadOrders();
        });
        // 🔄 بدء التحديث التلقائي
        _startPolling();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabCtrl?.dispose();
    super.dispose();
  }

  /// 🔔 نغمة إشعار مولّدة داخل الكود
  String _buildBeepUrl() {
    if (_beepUrl != null) return _beepUrl!;
    const sampleRate = 22050;
    const seconds = 0.35;
    const freq = 880.0;
    final n = (sampleRate * seconds).toInt();
    final dataSize = n * 2;
    final bytes = BytesBuilder();
    void addStr(String s) => bytes.add(s.codeUnits);
    void add32(int v) => bytes
        .add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
    void add16(int v) => bytes
        .add((ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List());
    addStr('RIFF');
    add32(36 + dataSize);
    addStr('WAVE');
    addStr('fmt ');
    add32(16);
    add16(1);
    add16(1);
    add32(sampleRate);
    add32(sampleRate * 2);
    add16(2);
    add16(16);
    addStr('data');
    add32(dataSize);
    final pcm = ByteData(dataSize);
    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      final env = (1 - t / seconds).clamp(0.0, 1.0);
      final v = (math.sin(2 * math.pi * freq * t) * env * 0.6 * 32767).round();
      pcm.setInt16(i * 2, v, Endian.little);
    }
    bytes.add(pcm.buffer.asUint8List());
    _beepUrl = 'data:audio/wav;base64,' + base64Encode(bytes.toBytes());
    return _beepUrl!;
  }

  void _playBeep() {
    try {
      final a = html.AudioElement(_buildBeepUrl());
      a.volume = 0.8;
      a.play();
    } catch (_) {}
  }

  /// 🔄 التحديث التلقائي كل 30 ثانية
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!mounted) return;
      await _silentRefresh();
    });
  }

  /// 🔇 تحديث صامت — يعمل في الخلفية
  Future<void> _silentRefresh() async {
    if (_isRefreshing || !mounted) return;
    _isRefreshing = true;
    try {
      final s = context.read<AppSettings>();
      final isAdmin = s.isAdmin || s.isImageAdmin;

      final newOrders = await OrdersService.loadOrders();

      if (!mounted) return;

      // 🔔 للمدير: نغمة + إشعار عند وصول طلب جديد
      if (isAdmin) {
        final newPending =
            newOrders.where((o) => o.status == 'pending').length;
        if (_lastPendingCount >= 0 && newPending > _lastPendingCount) {
          _playBeep();
          final diff = newPending - _lastPendingCount;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(s.isArabic
                  ? '🔔 وصل $diff طلب جديد!'
                  : '🔔 $diff new order(s)!'),
              backgroundColor: AppColors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ));
        }
        _lastPendingCount = newPending;
      }

      setState(() {
        _future = Future.value(newOrders);
      });
    } catch (_) {
    } finally {
      _isRefreshing = false;
    }
  }

  /// 👆 تحديث يدوي (بالسحب أو زر التحديث)
  Future<void> _manualRefresh() async {
    setState(() {
      _future = OrdersService.loadOrders();
    });
  }

  String _roleAr(String r) {
    if (r == 'agent') return 'وكيل';
    if (r == 'tech') return 'صباغ';
    if (r == 'admin') return 'مدير';
    return 'عميل';
  }

  String _statusAr(String st) {
    if (st == 'accepted') return 'مقبولة';
    if (st == 'rejected') return 'مرفوضة';
    return 'قيد المراجعة';
  }

  String _statusEn(String st) {
    if (st == 'accepted') return 'Accepted';
    if (st == 'rejected') return 'Rejected';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings s = context.watch<AppSettings>();
    final bool isAdmin = s.isAdmin || s.isImageAdmin;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF141419) : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isAdmin
            ? (s.isArabic ? 'إشعارات الطلبات' : 'Order notifications')
            : (s.isArabic ? 'طلباتي' : 'My orders')),
        actions: [
          // 🔄 زر التحديث اليدوي (متناسق مع الوضع الداكن)
          Container(
            margin: const EdgeInsets.only(left: 8, right: 8),
            decoration: BoxDecoration(
              color: dark
                  ? AppColors.orange.withAlpha(25)
                  : AppColors.orange.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.orange.withAlpha(60)),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.orange, size: 22),
              onPressed: _manualRefresh,
            ),
          ),
        ],
        bottom: isAdmin && _tabCtrl != null
            ? TabBar(
                controller: _tabCtrl,
                indicatorColor: AppColors.orange,
                labelColor: AppColors.orange,
                unselectedLabelColor:
                    dark ? Colors.grey.shade400 : Colors.grey.shade600,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                tabs: [
                  Tab(text: s.isArabic ? 'معلقة' : 'Pending'),
                  Tab(text: s.isArabic ? 'الكل' : 'All'),
                  Tab(text: s.isArabic ? 'مقبولة' : 'Accepted'),
                  Tab(text: s.isArabic ? 'مرفوضة' : 'Rejected'),
                ],
              )
            : null,
      ),
      body: RefreshIndicator(
        color: AppColors.orange,
        backgroundColor: dark ? const Color(0xFF1E1E28) : Colors.white,
        onRefresh: _manualRefresh,
        child: FutureBuilder<List<Order>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                snap.data == null) {
              return ListView(
                children: [
                  const SizedBox(height: 200),
                  const Center(child: CircularProgressIndicator()),
                ],
              );
            }
            var orders = snap.data ?? [];

            if (isAdmin) {
              if (_filter == 'pending') {
                orders = orders.where((o) => o.status == 'pending').toList();
              } else if (_filter == 'accepted') {
                orders = orders.where((o) => o.status == 'accepted').toList();
              } else if (_filter == 'rejected') {
                orders = orders.where((o) => o.status == 'rejected').toList();
              }
            } else {
              orders = orders.where((o) => o.userId == s.user?.id).toList();
            }

            if (orders.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                      child: Text(
                    s.isArabic ? 'لا توجد طلبات' : 'No orders',
                    style: TextStyle(
                        color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 15),
                  )),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _card(orders[i], isAdmin, s, dark),
            );
          },
        ),
      ),
    );
  }

  Widget _card(Order o, bool isAdmin, AppSettings s, bool dark) {
    final statusColor = o.status == 'accepted'
        ? AppColors.teal
        : (o.status == 'rejected' ? Colors.red : AppColors.orange);
    final statusBg = o.status == 'accepted'
        ? AppColors.teal.withAlpha(45)
        : (o.status == 'rejected'
            ? Colors.red.withAlpha(45)
            : AppColors.orange.withAlpha(45));

    return Pressable(
      onTap: () async {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => _OrderDetail(order: o, isAdmin: isAdmin)));
        if (mounted) {
          _manualRefresh();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E1E28) : Colors.white,
          gradient: dark
              ? null
              : LinearGradient(
                  colors: <Color>[
                    AppColors.orange.withAlpha(25),
                    Theme.of(context).colorScheme.surface
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.orange.withAlpha(70)),
          boxShadow: dark
              ? null
              : [
                  BoxShadow(
                      color: AppColors.orange.withAlpha(20),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isAdmin
                        ? '${o.userName} (${_roleAr(o.userRole)})'
                        : dmy(o.date),
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: dark ? Colors.white : AppColors.ink),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    s.isArabic ? _statusAr(o.status) : _statusEn(o.status),
                    style: TextStyle(
                        color: dark ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${dmy(o.date)} • ${o.items.length} ${s.isArabic ? 'المواد' : 'items'} • ${time12(o.id)}',
              style: TextStyle(
                  color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              s.isArabic ? 'عرض المزيد من التفاصيل' : 'View more details',
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderDetail extends StatefulWidget {
  final Order order;
  final bool isAdmin;
  const _OrderDetail({required this.order, required this.isAdmin});
  @override
  State<_OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<_OrderDetail> {
  final _total = TextEditingController();
  final _invNo = TextEditingController();
  bool _busy = false;

  double get _totalNum =>
      double.tryParse(_total.text.replaceAll(',', '')) ?? 0;
  int get _points => (_totalNum ~/ kPointUnit).toInt();
  int get _stored => (_totalNum % kPointUnit).toInt();

  String _roleAr(String r) {
    if (r == 'agent') return 'وكيل';
    if (r == 'tech') return 'صباغ';
    if (r == 'admin') return 'مدير';
    return 'عميل';
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      widget.order.total = _totalNum;
      widget.order.invoiceNo = _invNo.text.trim();
      await OrdersService.acceptOrder(widget.order);
      try {
        await context.read<AppSettings>().refreshUser();
      } catch (_) {}
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ تم قبول الفاتورة ونشرها'),
            backgroundColor: AppColors.teal));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل: $e')));
      }
    }
  }

  Future<void> _reject() async {
    setState(() => _busy = true);
    try {
      await OrdersService.rejectOrder(widget.order);
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('🗑️ تم رفض الفاتورة'),
            backgroundColor: Colors.red));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل: $e')));
      }
    }
  }

  Widget _field(String label, TextEditingController c, String hint) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      style: TextStyle(
          color: dark ? Colors.white : AppColors.ink, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: dark ? Colors.grey.shade300 : Colors.grey.shade700),
        hintText: hint,
        hintStyle: TextStyle(
            color: dark ? Colors.grey.shade500 : Colors.grey.shade400),
        filled: true,
        fillColor: dark ? const Color(0xFF26262E) : const Color(0xFFFFFDF9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _sumRow(String label, String value, Color c, {bool big = false}) {
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

  @override
  Widget build(BuildContext context) {
    final AppSettings s = context.watch<AppSettings>();
    final o = widget.order;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF141419) : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(s.isArabic ? 'تفاصيل الفاتورة' : 'Invoice details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: <Color>[
                    AppColors.teal.withAlpha(dark ? 40 : 25),
                    Theme.of(context).colorScheme.surface
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.teal.withAlpha(70)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${o.userName} (${_roleAr(o.userRole)})',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: dark ? Colors.white : AppColors.ink)),
                const SizedBox(height: 4),
                Text(
                    '${s.isArabic ? 'التاريخ' : 'Date'}: ${dmy(o.date)} • ${time12(o.id)}',
                    style: TextStyle(
                        color:
                            dark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 12)),
                const SizedBox(height: 10),
                ...o.items.map((it) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(it.name,
                                  style: TextStyle(
                                      color: dark
                                          ? Colors.white
                                          : AppColors.ink))),
                          Text('×${it.qty}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color:
                                      dark ? Colors.white : AppColors.ink)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 18),

          if (widget.isAdmin && o.status == 'pending') ...[
            _field(s.isArabic ? 'السعر الإجمالي' : 'Total', _total, '250000'),
            const SizedBox(height: 12),
            _field(s.isArabic ? 'رقم الفاتورة' : 'Invoice No', _invNo, '0001'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.orange.withAlpha(70)),
              ),
              child: Column(
                children: [
                  _sumRow(s.isArabic ? 'السعر الإجمالي' : 'Total',
                      fmtThousands(_totalNum), AppColors.orange,
                      big: true),
                  _sumRow(s.isArabic ? 'نقاط هذه الفاتورة' : 'Points',
                      fmtThousands(_points), AppColors.teal),
                  _sumRow(s.isArabic ? 'الرصيد المتبقي' : 'Remaining',
                      fmtThousands(_stored), AppColors.teal),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: <Color>[
                          Color(0xFF0D9668),
                          Color(0xFF0AA87A)
                        ]),
                        borderRadius: BorderRadius.circular(14)),
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white),
                        onPressed: _busy ? null : _accept,
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(s.isArabic ? 'قبول' : 'Accept',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: <Color>[
                          Color(0xFFD63C3C),
                          Color(0xFFB02A2A)
                        ]),
                        borderRadius: BorderRadius.circular(14)),
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white),
                        onPressed: _busy ? null : _reject,
                        child: Text(s.isArabic ? 'رفض' : 'Reject',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (o.status == 'accepted') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.teal.withAlpha(70)),
              ),
              child: Column(
                children: [
                  _sumRow(s.isArabic ? 'رقم الفاتورة' : 'Invoice No',
                      o.invoiceNo, AppColors.orange),
                  _sumRow(s.isArabic ? 'السعر الإجمالي' : 'Total',
                      fmtThousands(o.total), AppColors.orange),
                  _sumRow(s.isArabic ? 'النقاط' : 'Points',
                      fmtThousands(o.points), AppColors.teal),
                  _sumRow(s.isArabic ? 'الرصيد المتبقي' : 'Remaining',
                      fmtThousands(o.stored), AppColors.teal),
                ],
              ),
            ),
          ] else if (o.status == 'rejected') ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(dark ? 40 : 20),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.red.withAlpha(70)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.red, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    s.isArabic ? 'مرفوضة' : 'Rejected',
                    style: const TextStyle(
                        color: Colors.red,
                        fontSize: 22,
                        fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    s.isArabic
                        ? 'تم رفض الفاتورة للاستفسار يرجى مراجعة شركة فاوري'
                        : 'Invoice rejected. Please contact FAWORI company for inquiry.',
                    style: TextStyle(
                        color:
                            dark ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
