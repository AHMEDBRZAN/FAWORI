import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/orders_service.dart';
import '../core/theme.dart';
import '../widgets/pressable.dart';

String dmy(String iso) {
  try {
    final p = iso.split('-');
    return '${p[2].padLeft(2, '0')}-${p[1].padLeft(2, '0')}-${p[0]}';
  } catch (_) {
    return iso;
  }
}

String time12(String idMillis) {
  try {
    final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(idMillis));
    int h = dt.hour % 12;
    if (h == 0) h = 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? 'ص' : 'م'}';
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
  int _tabIndex = 0;
  int _lastVersion = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = context.read<AppSettings>();
      final isAdmin = s.isAdmin || s.isImageAdmin;
      _tabCtrl = TabController(length: isAdmin ? 5 : 4, vsync: this);
      _tabCtrl!.addListener(() {
        if (!_tabCtrl!.indexIsChanging) {
          setState(() => _tabIndex = _tabCtrl!.index);
        }
      });
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl?.dispose();
    super.dispose();
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
    if (st == 'returned') return 'مرتجعة';
    return 'قيد المراجعة';
  }

  Color _statusColor(String st) {
    if (st == 'accepted') return AppColors.teal;
    if (st == 'rejected') return Colors.red;
    if (st == 'returned') return const Color(0xFF9B59B6);
    return AppColors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings s = context.watch<AppSettings>();
    final bool isAdmin = s.isAdmin || s.isImageAdmin;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    // 🔄 تحديث تلقائي عند أي تغيير من الفحص العام
    final v = s.ordersVersion;
    if (v != _lastVersion) {
      _lastVersion = v;
      _future = OrdersService.loadOrders();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isAdmin
            ? (s.isArabic ? 'إشعارات الطلبات' : 'Order notifications')
            : (s.isArabic ? 'طلباتي' : 'My orders')),
        bottom: _tabCtrl == null
            ? null
            : TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                indicatorColor: AppColors.orange,
                labelColor: AppColors.orange,
                unselectedLabelColor:
                    dark ? Colors.grey.shade400 : Colors.grey.shade600,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                tabs: isAdmin
                    ? [
                        Tab(text: s.isArabic ? 'معلقة' : 'Pending'),
                        Tab(text: s.isArabic ? 'الكل' : 'All'),
                        Tab(text: s.isArabic ? 'مقبولة' : 'Accepted'),
                        Tab(text: s.isArabic ? 'مرفوضة' : 'Rejected'),
                        Tab(text: s.isArabic ? 'مرتجعة' : 'Returned'),
                      ]
                    : [
                        Tab(text: s.isArabic ? 'الكل' : 'All'),
                        Tab(text: s.isArabic ? 'مقبولة' : 'Accepted'),
                        Tab(text: s.isArabic ? 'مرفوضة' : 'Rejected'),
                        Tab(text: s.isArabic ? 'مرتجعة' : 'Returned'),
                      ],
              ),
      ),
      body: RefreshIndicator(
        color: AppColors.orange,
        backgroundColor: dark ? const Color(0xFF1E1E28) : Colors.white,
        onRefresh: () async {
          setState(() => _future = OrdersService.loadOrders());
        },
        child: FutureBuilder<List<Order>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                snap.data == null) {
              return ListView(children: const [
                SizedBox(height: 200),
                Center(child: CircularProgressIndicator()),
              ]);
            }
            var orders = snap.data ?? [];
            if (isAdmin) {
              switch (_tabIndex) {
                case 0:
                  orders =
                      orders.where((o) => o.status == 'pending').toList();
                  break;
                case 2:
                  orders =
                      orders.where((o) => o.status == 'accepted').toList();
                  break;
                case 3:
                  orders =
                      orders.where((o) => o.status == 'rejected').toList();
                  break;
                case 4:
                  orders =
                      orders.where((o) => o.status == 'returned').toList();
                  break;
              }
            } else {
              orders = orders.where((o) => o.userId == s.user?.id).toList();
              switch (_tabIndex) {
                case 1:
                  orders =
                      orders.where((o) => o.status == 'accepted').toList();
                  break;
                case 2:
                  orders =
                      orders.where((o) => o.status == 'rejected').toList();
                  break;
                case 3:
                  orders =
                      orders.where((o) => o.status == 'returned').toList();
                  break;
              }
            }
            if (orders.isEmpty) {
              return ListView(children: [
                const SizedBox(height: 120),
                Center(
                    child: Text(
                  s.isArabic ? 'لا توجد طلبات' : 'No orders',
                  style: TextStyle(
                      color: dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600),
                )),
              ]);
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
    final c = _statusColor(o.status);
    return Pressable(
      onTap: () async {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => _OrderDetail(order: o, isAdmin: isAdmin)));
        if (mounted) {
          setState(() => _future = OrdersService.loadOrders());
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E1E28) : Colors.white,
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
                      color: c.withAlpha(45),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    s.isArabic ? _statusAr(o.status) : o.status,
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
                  color: c, fontWeight: FontWeight.w800, fontSize: 13),
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

  Future<void> _return() async {
    setState(() => _busy = true);
    try {
      await OrdersService.markReturned(widget.order);
      try {
        await context.read<AppSettings>().refreshUser();
      } catch (_) {}
      if (mounted) {
        setState(() => _busy = false);
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
                        color: dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
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
                                  color: dark
                                      ? Colors.white
                                      : AppColors.ink)),
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
          ] else if (widget.isAdmin && o.status == 'accepted') ...[
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
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: <Color>[
                    Color(0xFF9B59B6),
                    Color(0xFF7D3C98)
                  ]),
                  borderRadius: BorderRadius.circular(14)),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white),
                  onPressed: _busy ? null : _return,
                  child: Text(
                      s.isArabic ? 'تحويل إلى مرتجع' : 'Mark as returned',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
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
          ] else if (o.status == 'returned') ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF9B59B6).withAlpha(dark ? 40 : 20),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF9B59B6).withAlpha(70)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.assignment_return_rounded,
                      color: Color(0xFF9B59B6), size: 56),
                  const SizedBox(height: 12),
                  Text(s.isArabic ? 'مرتجعة' : 'Returned',
                      style: const TextStyle(
                          color: Color(0xFF9B59B6),
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  _sumRow(s.isArabic ? 'النقاط المخصومة' : 'Points deducted',
                      '-${fmtThousands(o.points)}', Colors.red),
                  _sumRow(s.isArabic ? 'الرصيد المخصوم' : 'Stored deducted',
                      '-${fmtThousands(o.stored)}', Colors.red),
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
                  Text(s.isArabic ? 'مرفوضة' : 'Rejected',
                      style: const TextStyle(
                          color: Colors.red,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  Text(
                    s.isArabic
                        ? 'تم رفض الفاتورة للاستفسار يرجى مراجعة شركة فاوري'
                        : 'Invoice rejected. Please contact FAWORI company.',
                    style: TextStyle(
                        color: dark ? Colors.white : Colors.black87,
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
