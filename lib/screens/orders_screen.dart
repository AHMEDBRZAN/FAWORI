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

  String _roleAr(String r) {
    if (r == 'agent') return 'وكيل';
    if (r == 'tech') return 'صباغ';
    if (r == 'admin') return 'مدير';
    return 'عميل';
  }

  String _statusAr(String st) {
    if (st == 'accepted') return 'مقبولة';
    return 'قيد المراجعة';
  }

  String _statusEn(String st) {
    if (st == 'accepted') return 'Accepted';
    return 'Pending';
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
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _future = OrdersService.loadOrders();
          });
        },
        child: FutureBuilder<List<Order>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            var orders = snap.data ?? [];
            if (isAdmin) {
              orders = orders.where((o) => o.status == 'pending').toList();
            } else {
              orders = orders.where((o) => o.userId == s.user?.id).toList();
            }
            if (orders.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                      child: Text(s.isArabic ? 'لا توجد طلبات' : 'No orders')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _card(orders[i], isAdmin, s),
            );
          },
        ),
      ),
    );
  }

  Widget _card(Order o, bool isAdmin, AppSettings s) {
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
                AppColors.orange.withAlpha(25),
                Theme.of(context).colorScheme.surface
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.orange.withAlpha(70)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isAdmin ? '${o.userName} (${_roleAr(o.userRole)})' : o.date,
                    style:
                        const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: o.status == 'accepted'
                          ? AppColors.teal.withAlpha(35)
                          : AppColors.orange.withAlpha(35),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    s.isArabic ? _statusAr(o.status) : _statusEn(o.status),
                    style: TextStyle(
                        color: o.status == 'accepted'
                            ? AppColors.teal
                            : AppColors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('${o.items.length} ${s.isArabic ? 'مادة' : 'items'} • ${o.date}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              s.isArabic ? 'عرض المزيد من التفاصيل' : 'View more details',
              style: const TextStyle(
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

  Future<void> _reject() async {
    setState(() => _busy = true);
    try {
      await OrdersService.rejectOrder(widget.order);
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🗑️ تم رفض الفاتورة وحذفها')));
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
      style: TextStyle(color: dark ? Colors.white : AppColors.ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: dark ? const Color(0xFF26262E) : const Color(0xFFFFFDF9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _sumRow(String label, String value, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          Text(value,
              style:
                  TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 15)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings s = context.watch<AppSettings>();
    final o = widget.order;
    return Scaffold(
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
                    AppColors.teal.withAlpha(25),
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text('${s.isArabic ? 'التاريخ' : 'Date'}: ${o.date}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 10),
                ...o.items.map((it) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(it.name)),
                          Text('×${it.qty}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
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
                      fmtThousands(_totalNum), AppColors.orange),
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
                        gradient: const LinearGradient(
                            colors: <Color>[
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
                        gradient: const LinearGradient(
                            colors: <Color>[
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
          ],
        ],
      ),
    );
  }
}
