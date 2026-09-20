import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<List<Order>> _loadAndMark() async {
    final os = await OrdersService.loadOrders();
    if (mounted) {
      await context.read<AppSettings>().markAllSeen();
    }
    return os;
  }

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
      setState(() {
        _future = _loadAndMark();
      });
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

    final v = s.ordersVersion;
    if (v != _lastVersion) {
      _lastVersion = v;
      _future = _loadAndMark();
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
          setState(() => _future = _loadAndMark());
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
                      color:
                          dark ? Colors.grey.shade400 : Colors.grey.shade600),
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
          setState(() => _future = _loadAndMark());
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
  bool _busy = false;
  List<Map<String, dynamic>> _returns = [];

  @override
  void initState() {
    super.initState();
    _loadReturns();
  }

  Future<void> _loadReturns() async {
    try {
      final rets = await OrdersService.loadReturns();
      if (mounted) {
        setState(() {
          _returns = rets
              .where((r) => r['orderId'] == widget.order.id)
              .toList();
        });
      }
    } catch (_) {}
  }

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

  String _fmtInput(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    return fmtThousands(int.parse(digits));
  }

  void _applyMoneyFormat(TextEditingController c) {
    final f = _fmtInput(c.text);
    if (f != c.text) {
      c.value = TextEditingValue(
        text: f,
        selection: TextSelection.collapsed(offset: f.length),
      );
    }
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      widget.order.total = _totalNum;
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

  /// 🔄 نافذة المرتجع: حقول فارغة + فواصل تلقائية في السعر
  Future<void> _showReturnDialog() async {
    final s = context.read<AppSettings>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, Object>> items = widget.order.items
        .map((it) => <String, Object>{
              'name': it.name,
              'max': it.qty,
              'qty': it.qty,
            })
        .toList();

    final totalCtrl = TextEditingController();
    final invCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: dark ? const Color(0xFF1E1E28) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            s.isArabic ? 'تحويل إلى مرتجع' : 'Mark as returned',
            style: const TextStyle(
                color: Color(0xFF9B59B6),
                fontWeight: FontWeight.w900,
                fontSize: 18),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.isArabic
                        ? 'حدّد المواد المرتجعة وكمياتها:'
                        : 'Select returned items and quantities:',
                    style: TextStyle(
                        color: dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(items.length, (i) {
                    final name = items[i]['name'] as String;
                    final qty = items[i]['qty'] as int;
                    final max = items[i]['max'] as int;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: qty > 0
                            ? const Color(0xFF9B59B6).withAlpha(20)
                            : (dark
                                ? const Color(0xFF26262E)
                                : const Color(0xFFF5F5F5)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: qty > 0
                                ? const Color(0xFF9B59B6).withAlpha(80)
                                : Colors.grey.withAlpha(40)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                  color: dark ? Colors.white : AppColors.ink,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: dark
                                  ? const Color(0xFF26262E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFF9B59B6)
                                      .withAlpha(60)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: qty > 0
                                      ? () => setDialogState(
                                          () => items[i]['qty'] = qty - 1)
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    child: Icon(Icons.remove,
                                        size: 18,
                                        color: qty > 0
                                            ? const Color(0xFF9B59B6)
                                            : Colors.grey),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  child: Text('$qty / $max',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: dark
                                              ? Colors.white
                                              : AppColors.ink)),
                                ),
                                InkWell(
                                  onTap: qty < max
                                      ? () => setDialogState(
                                          () => items[i]['qty'] = qty + 1)
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    child: Icon(Icons.add,
                                        size: 18,
                                        color: qty < max
                                            ? const Color(0xFF9B59B6)
                                            : Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  // ✅ سعر المرتجع: فواصل تلقائية أثناء الكتابة
                  TextField(
                    controller: totalCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      _applyMoneyFormat(totalCtrl);
                      setDialogState(() {});
                    },
                    style: TextStyle(
                        color: dark ? Colors.white : AppColors.ink,
                        fontSize: 16),
                    decoration: InputDecoration(
                      hintText: s.isArabic
                          ? 'اكتب سعر المرتجع'
                          : 'Write return price',
                      hintStyle: TextStyle(
                          color: dark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.payments_outlined,
                          color: AppColors.orange),
                      filled: true,
                      fillColor: dark
                          ? const Color(0xFF26262E)
                          : const Color(0xFFFFFDF9),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: invCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    style: TextStyle(
                        color: dark ? Colors.white : AppColors.ink,
                        fontSize: 16),
                    decoration: InputDecoration(
                      hintText: s.isArabic
                          ? 'اكتب رقم فاتورة المرتجع'
                          : 'Write return invoice No',
                      hintStyle: TextStyle(
                          color: dark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.receipt_long_outlined,
                          color: AppColors.teal),
                      filled: true,
                      fillColor: dark
                          ? const Color(0xFF26262E)
                          : const Color(0xFFFFFDF9),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.isArabic ? 'إلغاء' : 'Cancel',
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B59B6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final anySelected =
                    items.any((it) => (it['qty'] as int) > 0);
                if (!anySelected) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(s.isArabic
                          ? 'اختر مادة واحدة على الأقل'
                          : 'Select at least one item')));
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(s.isArabic ? 'تحويل مرتجع' : 'Mark returned',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) return;

    final customTotal =
        double.tryParse(totalCtrl.text.replaceAll(',', '')) ?? 0;
    if (customTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              s.isArabic ? 'أدخل سعر المرتجع' : 'Enter return price'),
          backgroundColor: Colors.red));
      return;
    }
    final customInv = invCtrl.text.trim();

    setState(() => _busy = true);
    try {
      final returnedItems = items
          .where((it) => (it['qty'] as int) > 0)
          .map((it) => OrderItem(
              name: it['name'] as String, qty: it['qty'] as int))
          .toList();

      await OrdersService.markReturned(
        widget.order,
        returnedItems: returnedItems,
        customTotal: customTotal,
        customInvoiceNo: customInv,
      );
      try {
        await context.read<AppSettings>().refreshUser();
      } catch (_) {}
      if (mounted) {
        setState(() => _busy = false);
        _loadReturns();
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

  /// ✅ بطاقة الملاحظة — تظهر فقط إذا يوجد مرتجع
  Widget _noteCard(AppSettings s, bool dark) {
    return Pressable(
      onTap: _showReturnsDialog,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF9B59B6).withAlpha(dark ? 40 : 20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF9B59B6).withAlpha(80)),
        ),
        child: Row(
          children: [
            const Icon(Icons.sticky_note_2_rounded,
                color: Color(0xFF9B59B6), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.isArabic
                    ? 'ملاحظة: يوجد مرتجع على هذه الفاتورة'
                    : 'Note: this invoice has a return',
                style: TextStyle(
                    color: dark ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_left_rounded,
                color: Color(0xFF9B59B6)),
          ],
        ),
      ),
    );
  }

  /// 🪟 نافذة المرتجعات
  void _showReturnsDialog() {
    final s = context.read<AppSettings>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: dark ? const Color(0xFF1E1E28) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.isArabic ? 'المرتجعات' : 'Returns',
                    style: const TextStyle(
                        color: Color(0xFF9B59B6),
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
                const SizedBox(height: 12),
                for (final r in _returns) ...[
                  _retCard(r, s, dark),
                  const SizedBox(height: 12),
                ],
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(s.isArabic ? 'إغلاق' : 'Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 📋 بطاقة مرتجع: رأس + فاتورة الشراء + جدول + الخصومات
  Widget _retCard(Map<String, dynamic> r, AppSettings s, bool dark) {
    final items = List<Map<String, dynamic>>.from((r['items'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map)));
    final no = '${r['no'] ?? ''}';
    final pNo = '${r['purchaseNo'] ?? ''}';
    final date = '${r['date'] ?? ''}';
    final total = ((r['total'] as num?)?.toInt() ?? 0);
    final pts = ((r['points'] as num?)?.toInt() ?? 0);
    final st = ((r['stored'] as num?)?.toInt() ?? 0);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF9B59B6).withAlpha(60)),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFF9B59B6).withAlpha(dark ? 50 : 30),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: Color(0xFF9B59B6)),
                const SizedBox(width: 6),
                Text(dmy(date),
                    style: const TextStyle(
                        color: Color(0xFF9B59B6),
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
                const Spacer(),
                const Icon(Icons.assignment_return_rounded,
                    size: 14, color: Color(0xFF9B59B6)),
                const SizedBox(width: 6),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(no.isEmpty ? '—' : no,
                      style: const TextStyle(
                          color: Color(0xFF9B59B6),
                          fontWeight: FontWeight.w900,
                          fontSize: 12)),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: const Color(0xFF9B59B6).withAlpha(dark ? 30 : 18),
            child: Row(
              children: [
                Text(
                    s.isArabic
                        ? 'فاتورة الشراء المرتبط بها'
                        : 'Linked purchase invoice',
                    style: TextStyle(
                        color: dark ? Colors.grey.shade200 : AppColors.ink,
                        fontSize: 11,
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
          for (int i = 0; i < items.length; i++)
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              color: i.isOdd
                  ? (dark
                      ? Colors.white.withAlpha(8)
                      : Colors.black.withAlpha(6))
                  : Colors.transparent,
              child: Row(
                children: [
                  SizedBox(
                      width: 30,
                      child: Text('${i + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: dark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w800))),
                  Expanded(
                      child: Text('${items[i]['name']}',
                          style: TextStyle(
                              color: dark ? Colors.white : AppColors.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700))),
                  SizedBox(
                      width: 50,
                      child: Center(
                        child: Text('${items[i]['qty']}',
                            style: const TextStyle(
                                color: Color(0xFF9B59B6),
                                fontWeight: FontWeight.w900,
                                fontSize: 12)),
                      )),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFF9B59B6).withAlpha(dark ? 30 : 15),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(s.isArabic ? 'إجمالي المرتجع' : 'Return total',
                        style: TextStyle(
                            color: dark ? Colors.white : AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text('-${fmtThousands(total)}',
                          style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w900,
                              fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                        s.isArabic
                            ? 'نقاط مخصومة منه'
                            : 'Points deducted',
                        style: TextStyle(
                            color: dark ? Colors.white : AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text('-${fmtThousands(pts)}',
                          style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w900,
                              fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                        s.isArabic
                            ? 'رصيد مخزن مخصوم منه'
                            : 'Stored deducted',
                        style: TextStyle(
                            color: dark ? Colors.white : AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text('-${fmtThousands(st)}',
                          style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w900,
                              fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyField(String hint, TextEditingController c) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      onChanged: (_) {
        _applyMoneyFormat(c);
        setState(() {});
      },
      style:
          TextStyle(color: dark ? Colors.white : AppColors.ink, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: dark ? Colors.grey.shade500 : Colors.grey.shade400,
            fontSize: 15),
        prefixIcon: const Icon(Icons.payments_outlined,
            color: AppColors.orange, size: 22),
        filled: true,
        fillColor: dark ? const Color(0xFF26262E) : const Color(0xFFFFFDF9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            _moneyField(s.isArabic ? 'السعر الإجمالي' : 'Total', _total),
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
                  _sumRow(s.isArabic ? 'رقم الفاتورة' : 'Invoice No',
                      o.invoiceNo.isEmpty ? '—' : o.invoiceNo,
                      AppColors.orange),
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
            if (_returns.isNotEmpty) ...[
              const SizedBox(height: 14),
              _noteCard(s, dark),
            ],
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
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white),
                  onPressed: _busy ? null : _showReturnDialog,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.assignment_return_rounded),
                  label: Text(
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
            if (_returns.isNotEmpty) ...[
              const SizedBox(height: 14),
              _noteCard(s, dark),
            ],
          ] else if (o.status == 'returned') ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF9B59B6).withAlpha(dark ? 40 : 20),
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: const Color(0xFF9B59B6).withAlpha(70)),
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
                  _sumRow(s.isArabic ? 'رقم الفاتورة' : 'Invoice No',
                      o.invoiceNo, AppColors.orange),
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
                  const SizedBox(height: 8),
                  _sumRow(s.isArabic ? 'رقم الفاتورة' : 'Invoice No',
                      o.invoiceNo, AppColors.orange),
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
