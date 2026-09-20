import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/orders_service.dart';
import '../core/theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _items = [];
  bool _loading = true;
  bool _busy = false;
  final _invNo = TextEditingController();

  /// ✅ سلسلة كتابة متسلسلة: لا عملية حفظ تكتمل بعد التفريغ
  Future<void> _writeChain = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _invNo.dispose();
    super.dispose();
  }

  /// ✅ تحميل لحظي من التخزين عند كل فتح
  Future<void> _load() async {
    final s = context.read<AppSettings>();
    try {
      final cart = await OrdersService.loadCart(s.user?.id ?? '');
      if (mounted) {
        setState(() {
          _items = cart;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// ✅ حفظ عبر السلسلة المتسلسلة
  Future<void> _save() async {
    final s = context.read<AppSettings>();
    final snapshot = List<CartItem>.from(_items);
    _writeChain = _writeChain
        .then((_) => OrdersService.saveCart(s.user?.id ?? '', snapshot));
    await _writeChain;
  }

  Future<void> _chg(int i, int d) async {
    setState(() {
      _items[i].qty = (_items[i].qty + d).clamp(1, 99);
    });
    await _save();
  }

  Future<void> _remove(int i) async {
    setState(() => _items.removeAt(i));
    await _save();
  }

  Future<void> _checkout() async {
    final s = context.read<AppSettings>();
    final inv = _invNo.text.trim();
    if (inv.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              s.isArabic ? 'أدخل رقم الفاتورة أولاً' : 'Enter invoice number first'),
          backgroundColor: Colors.red));
      return;
    }
    if (_items.isEmpty) return; // ✅ بدون أي إشعار إذا كانت فارغة
    setState(() => _busy = true);
    try {
      // ✅ انتظر أي عمليات حفظ معلّقة
      await _writeChain;
      final captured = List<CartItem>.from(_items);

      // ✅ تفريغ فوري (ذاكرة + تخزين) قبل الإرسال
      setState(() {
        _items = [];
      });
      await OrdersService.clearCart(s.user?.id ?? '');

      final now = DateTime.now();
      final order = Order(
        id: '${now.millisecondsSinceEpoch}',
        userId: s.user?.id ?? '',
        userName: s.user?.name ?? '',
        userRole: s.user?.role ?? '',
        date:
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        items: captured
            .map((e) => OrderItem(name: e.name, qty: e.qty))
            .toList(),
        invoiceNo: inv,
      );
      await OrdersService.submitOrder(order);
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(s.isArabic
                ? '✅ تم إرسال الطلب إلى الإدارة'
                : 'Order sent to admin')));
        Navigator.pop(context, true);
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(s.isArabic ? 'السلة' : 'Cart'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text(
                      s.isArabic ? 'السلة فارغة' : 'Cart is empty',
                      style: TextStyle(color: Colors.grey.shade500)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (int i = 0; i < _items.length; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: dark
                              ? const Color(0xFF1E1E28)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.orange.withAlpha(60)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(_items[i].name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: dark
                                          ? Colors.white
                                          : AppColors.ink)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: AppColors.orange),
                              onPressed: _items[i].qty > 1
                                  ? () => _chg(i, -1)
                                  : null,
                            ),
                            Text('${_items[i].qty}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: AppColors.orange),
                              onPressed: () => _chg(i, 1),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _remove(i),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _invNo,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      style: TextStyle(
                          color: dark ? Colors.white : AppColors.ink,
                          fontSize: 16),
                      decoration: InputDecoration(
                        hintText:
                            s.isArabic ? 'رقم الفاتورة' : 'Invoice No',
                        hintStyle: TextStyle(
                            color: dark
                                ? Colors.grey.shade500
                                : Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.receipt_long_outlined,
                            color: AppColors.teal, size: 22),
                        filled: true,
                        fillColor: dark
                            ? const Color(0xFF26262E)
                            : const Color(0xFFFFFDF9),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: <Color>[
                              AppColors.orange.withAlpha(dark ? 40 : 25),
                              Theme.of(context).colorScheme.surface
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: AppColors.orange.withAlpha(70)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                  s.isArabic
                                      ? 'السعر الإجمالي'
                                      : 'Total',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: dark
                                          ? Colors.white
                                          : AppColors.ink)),
                              const Spacer(),
                              Text(
                                  s.isArabic
                                      ? 'يُحدد من الإدارة'
                                      : 'Set by admin',
                                  style: const TextStyle(
                                      color: AppColors.orange,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                  s.isArabic
                                      ? 'نقاط هذه الفاتورة'
                                      : 'Invoice points',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: dark
                                          ? Colors.white
                                          : AppColors.ink)),
                              const Spacer(),
                              const Text('—',
                                  style: TextStyle(
                                      color: AppColors.teal,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                  s.isArabic
                                      ? 'الرصيد المتبقي'
                                      : 'Remaining',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: dark
                                          ? Colors.white
                                          : AppColors.ink)),
                              const Spacer(),
                              const Text('—',
                                  style: TextStyle(
                                      color: AppColors.teal,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: <Color>[
                            Color(0xFFE8A33C),
                            Color(0xFFF26B0F)
                          ]),
                          borderRadius: BorderRadius.circular(14)),
                      child: SizedBox(
                        height: 54,
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white),
                          onPressed: _busy ? null : _checkout,
                          child: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(
                                  s.isArabic ? 'إتمام الشراء' : 'Checkout',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
