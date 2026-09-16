import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/orders_service.dart';
import '../core/theme.dart';
import '../widgets/pressable.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Order>> _future = OrdersService.loadOrders();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _future = OrdersService.loadOrders();
        });
      }
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
    if (st == 'return_pending') return 'مرتجع قيد المراجعة';
    if (st == 'return_accepted') return 'مرتجع مقبول';
    return 'قيد المراجعة';
  }

  String _statusEn(String st) {
    if (st == 'accepted') return 'Accepted';
    if (st == 'return_pending') return 'Return pending';
    if (st == 'return_accepted') return 'Return accepted';
    return 'Pending';
  }

  Color _statusColor(String st) {
    if (st == 'accepted') return AppColors.teal;
    if (st == 'return_pending' || st == 'return_accepted') {
      return const Color(0xFFD63C3C);
    }
    return AppColors.orange;
  }

  Widget _header(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(t,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings s = context.watch<AppSettings>();
    final bool isAdmin = s.isAdmin || s.isImageAdmin;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isAdmin
            ? (s.isArabic ? 'إشعارات الطلبات' : 'Order notifications')
            : (s.isArabic ? 'طلباتي' : 'My orders')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.orange),
            onPressed: () {
              setState(() {
                _future = OrdersService.loadOrders();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Order>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data ?? [];
          if (isAdmin) {
            final list = all
                .where((o) =>
                    o.status == 'pending' || o.status == 'return_pending')
                .toList();
            if (list.isEmpty) {
              return Center(
                  child: Text(s.isArabic ? 'لا توجد طلبات' : 'No orders'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _card(list[i], isAdmin, s),
            );
          }
          // ===== وضع المستخدم: أقسام =====
          final mine = all.where((o) => o.userId == s.user?.id).toList();
          final pending = mine
              .where((o) => o.status == 'pending' || o.status == 'return_pending')
              .toList();
          final done = mine
              .where((o) =>
                  o.status == 'accepted' || o.status == 'return_accepted')
              .toList();
          if (mine.isEmpty) {
            return Center(
                child: Text(s.isArabic ? 'لا توجد طلبات' : 'No orders'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                _header(s.isArabic ? 'قيد المراجعة' : 'Pending'),
                ...pending.map((o) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _card(o, isAdmin, s),
                    )),
                const SizedBox(height: 8),
              ],
              if (done.isNotEmpty) ...[
                _header(s.isArabic ? 'السجل' : 'History'),
                ...done.map((o) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _card(o, isAdmin, s),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _card(Order o, bool isAdmin, AppSettings s) {
    final bool isReturn = o.status.startsWith('return');
    final Color c = _statusColor(o.status);
    return Pressable(
      onTap: () async {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => _OrderDetail(order: o, isAdmin: isAdmin)));
        if (mounted) {
          setState(() {
            _future = OrdersService.loadOrders();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: <Color>[
                c.withAlpha(25),
                Theme.of(context).colorScheme.surface
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.withAlpha(70)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isAdmin
                        ? (isReturn
                            ? '${s.isArabic ? 'طلب مرتجع' : 'Return'} — ${o.userName}'
                            : '${o.userName} (${_roleAr(o.userRole)})')
                        : (isReturn
                            ? (s.isArabic ? 'طلب مرتجع' : 'Return request')
                            : o.date),
                    style:
                        const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: c.withAlpha(45),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    s.isArabic ? _statusAr(o.status) : _statusEn(o.status),
                    style: TextStyle(
                        color: c, fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
                '${o.items.length} ${s.isArabic ? 'مادة' : 'items'} • ${o.date}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              s.isArabic ? 'عرض المزيد من التفاصيل' : 'View more details',
              style: TextStyle(
                  color: AppColors.teal,
                  fontWeight: FontWeight.w800,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// التفاصيل
// ======================================================

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
      double.tryParse(_total.text.replaceAll(',', '').replaceAll('،', '')) ?? 0;
  int get _points => (_totalNum / kPointUnit).floor();
  int get _stored => (_totalNum - (_points * kPointUnit)).toInt();

  String _roleAr(String r) {
    if (r == 'agent') return 'وكيل';
    if (r == 'tech') return 'صباغ';
    if (r == 'admin') return 'مدير';
    return 'عميل';
  }

  Future<void> _accept() async {
    if (_totalNum <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('أدخل السعر الإجمالي أولاً')));
      return;
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم قبول الفاتورة ونشرها')));
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

  Future<void> _acceptReturn() async {
    if (_totalNum <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل السعر الإجمالي للمرتجع أولاً')));
      return;
    }
    setState(() => _busy = true);
    try {
      widget.order.total = _totalNum;
      widget.order.invoiceNo = _invNo.text.trim();
      await OrdersService.acceptReturn(widget.order);
      try {
        await context.read<AppSettings>().refreshUser();
      } catch (_) {}
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ تم قبول المرتجع وتعديل الفاتورة الأصلية')));
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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🗑️ تم الرفض والحذف')));
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

  /// ✅ فتح نافذة اختيار مواد المرتجع
  Future<void> _tryReturn() async {
    final orders = await OrdersService.loadOrders();
    if (!mounted) return;
    final exists = orders.any((x) =>
        x.origId == widget.order.id && x.status == 'return_pending');
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('يوجد طلب مرتجع قيد المراجعة لهذه الفاتورة')));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ReturnSheet(order: widget.order),
    );
  }

  Widget _field(String label, TextEditingController c, String hint) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: dark ? Colors.white : AppColors.ink, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: dark ? const Color(0xFF26262E) : const Color(0xFFFFFDF9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _sumRow(String label, String value, Color c, {bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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

  Widget _buttons(VoidCallback onOk, String okLabel, Color okColor) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: <Color>[okColor, okColor.withAlpha(200)]),
                borderRadius: BorderRadius.circular(14)),
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white),
                onPressed: _busy ? null : onOk,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(okLabel,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: <Color>[Color(0xFFD63C3C), Color(0xFFB02A2A)]),
                borderRadius: BorderRadius.circular(14)),
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white),
                onPressed: _busy ? null : _reject,
                child: const Text('رفض',
                    style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings s = context.watch<AppSettings>();
    final o = widget.order;
    final bool isReturn = o.status.startsWith('return');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isReturn
            ? (s.isArabic ? 'تفاصيل المرتجع' : 'Return details')
            : (s.isArabic ? 'تفاصيل الفاتورة' : 'Invoice details')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: <Color>[
                    (isReturn ? const Color(0xFFD63C3C) : AppColors.teal)
                        .withAlpha(25),
                    Theme.of(context).colorScheme.surface
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: (isReturn ? const Color(0xFFD63C3C) : AppColors.teal)
                      .withAlpha(70)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${isReturn ? (s.isArabic ? 'طلب مرتجع — ' : 'Return — ') : ''}${o.userName} (${_roleAr(o.userRole)})',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text('${s.isArabic ? 'التاريخ' : 'Date'}: ${o.date}',
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 10),
                ...o.items.map((it) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(it.name)),
                          Text('×${it.qty}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // ===== مدير: فاتورة شراء معلقة =====
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
                      fmtThousands(_totalNum), AppColors.orange, big: true),
                  _sumRow(s.isArabic ? 'نقاط هذه الفاتورة' : 'Points',
                      fmtThousands(_points), AppColors.teal),
                  _sumRow(s.isArabic ? 'الرصيد المتبقي' : 'Remaining',
                      fmtThousands(_stored), AppColors.teal),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _buttons(_accept, s.isArabic ? 'قبول' : 'Accept',
                const Color(0xFF0D9668)),
          ],
          // ===== مدير: مرتجع معلق =====
          if (widget.isAdmin && o.status == 'return_pending') ...[
            _field(
                s.isArabic
                    ? 'السعر الإجمالي للمرتجع'
                    : 'Return total',
                _total,
                '50000'),
            const SizedBox(height: 12),
            _field(
                s.isArabic ? 'رقم فاتورة المرتجع' : 'Return invoice No',
                _invNo,
                'R-0001'),
            const SizedBox(height: 18),
            _buttons(_acceptReturn, s.isArabic ? 'قبول المرتجع' : 'Accept return',
                const Color(0xFF0D9668)),
          ],
          // ===== مقبولة (شراء): الملخص + زر مرتجع للمستخدم =====
          if (o.status == 'accepted') ...[
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
                      fmtThousands(o.total), AppColors.orange, big: true),
                  _sumRow(s.isArabic ? 'النقاط' : 'Points',
                      fmtThousands(o.points), AppColors.teal),
                  _sumRow(s.isArabic ? 'الرصيد المتبقي' : 'Remaining',
                      fmtThousands(o.stored), AppColors.teal),
                ],
              ),
            ),
            if (o.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
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
                        child: Text(o.note,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
            ],
            if (!widget.isAdmin) ...[
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: <Color>[Color(0xFFD63C3C), Color(0xFFB02A2A)]),
                    borderRadius: BorderRadius.circular(14)),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white),
                    onPressed: _tryReturn,
                    child: Text(
                        s.isArabic ? 'طلب مرتجع' : 'Return request',
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ],
          ],
          // ===== مرتجع مقبول =====
          if (o.status == 'return_accepted') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: const Color(0xFFD63C3C).withAlpha(70)),
              ),
              child: Column(
                children: [
                  _sumRow(s.isArabic ? 'رقم فاتورة المرتجع' : 'Return No',
                      o.invoiceNo, const Color(0xFFD63C3C)),
                  _sumRow(s.isArabic ? 'قيمة المرتجع' : 'Return value',
                      fmtThousands(o.total), const Color(0xFFD63C3C),
                      big: true),
                ],
              ),
            ),
            if (o.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
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
                        child: Text(o.note,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ======================================================
// نافذة اختيار مواد المرتجع
// ======================================================

class _ReturnSheet extends StatefulWidget {
  final Order order;
  const _ReturnSheet({required this.order});
  @override
  State<_ReturnSheet> createState() => _ReturnSheetState();
}

class _ReturnSheetState extends State<_ReturnSheet> {
  late final Map<String, int> _qty =
      {for (final it in widget.order.items) it.name: 0};
  bool _busy = false;

  int _maxOf(String name) =>
      widget.order.items.firstWhere((e) => e.name == name).qty;

  Future<void> _submit() async {
    final selected = widget.order.items
        .where((e) => (_qty[e.name] ?? 0) > 0)
        .map((e) => OrderItem(name: e.name, qty: _qty[e.name]!))
        .toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدد كمية واحدة على الأقل')));
      return;
    }
    setState(() => _busy = true);
    try {
      final o = widget.order;
      await OrdersService.submitOrder(Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: o.userId,
        userName: o.userName,
        userRole: o.userRole,
        date: DateTime.now().toString().substring(0, 10),
        items: selected,
        status: 'return_pending',
        origId: o.id,
      ));
      if (mounted) {
        setState(() => _busy = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ تم إرسال طلب المرتجع إلى الإدارة')));
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
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
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
            Text(
              s.isArabic
                  ? 'حدد المواد والكميات المرتجعة'
                  : 'Select returned items',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            ...widget.order.items.map((it) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFD63C3C).withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            Text(
                                '${s.isArabic ? 'المشتراة' : 'bought'}: ${it.qty}',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Color(0xFFD63C3C)),
                        onPressed: (_qty[it.name] ?? 0) > 0
                            ? () => setState(
                                () => _qty[it.name] = _qty[it.name]! - 1)
                            : null,
                      ),
                      Text('${_qty[it.name] ?? 0}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: Color(0xFFD63C3C)),
                        onPressed: (_qty[it.name] ?? 0) < _maxOf(it.name)
                            ? () => setState(
                                () => _qty[it.name] = _qty[it.name]! + 1)
                            : null,
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: <Color>[Color(0xFFD63C3C), Color(0xFFB02A2A)]),
                  borderRadius: BorderRadius.circular(14)),
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white),
                  onPressed: _busy ? null : _submit,
                  child: Text(
                      s.isArabic ? 'إرسال طلب المرتجع' : 'Submit return',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
