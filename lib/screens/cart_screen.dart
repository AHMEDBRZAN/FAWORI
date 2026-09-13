import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/orders_service.dart';
import '../core/store_service.dart';
import '../core/theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _cart = [];
  String _uid = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = context.read<AppSettings>();
    if (s.user == null) return;
    _uid = s.user!.id;
    final c = await OrdersService.loadCart(_uid);
    if (mounted) setState(() => _cart = c);
  }

  Future<void> _save() async {
    await OrdersService.saveCart(_uid, _cart);
    setState(() {});
  }

  Future<void> _submit({bool isRetry = false}) async {
    final s = context.read<AppSettings>();
    if (s.user == null || _cart.isEmpty) return;
    setState(() => _busy = true);
    try {
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: s.user!.id,
        userName: s.user!.name,
        userRole: s.user!.role,
        date: DateTime.now().toString().substring(0, 10),
        items: _cart.map((c) => OrderItem(name: c.name, qty: c.qty)).toList(),
      );
      await OrdersService.submitOrder(order);
      await OrdersService.clearCart(_uid);
      if (mounted) {
        setState(() {
          _cart = [];
          _busy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم إرسال الفاتورة إلى الإدارة')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      // 🛡️ عند 401: اطلب توكن (يُحفظ داخلياً في ImagesService._memToken)
      // ثم أعد المحاولة — OrdersService._resolveOrderToken سيستعيده تلقائياً
      if (!isRetry && e.toString().contains('401')) {
        setState(() => _busy = false);
        final t = await ImagesService.askGitHubToken(context);
        if (t != null && t.isNotEmpty) {
          await _submit(isRetry: true);
        }
        return;
      }
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('فشل الإرسال: $e')));
    }
  }

  Widget _row(CartItem c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange.withAlpha(60)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(c.name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
          IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppColors.orange),
              onPressed: () {
                if (c.qty > 1) {
                  c.qty--;
                  _save();
                }
              }),
          Text('${c.qty}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.orange),
              onPressed: () {
                c.qty++;
                _save();
              }),
          IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                _cart.remove(c);
                _save();
              }),
        ],
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
              style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 15)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings s = context.watch<AppSettings>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(s.isArabic ? 'السلة' : 'Cart'),
      ),
      body: _cart.isEmpty
          ? Center(child: Text(s.isArabic ? 'السلة فارغة' : 'Cart is empty'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ..._cart.map(_row),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: <Color>[
                          AppColors.orange.withAlpha(30),
                          Theme.of(context).colorScheme.surface
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.orange.withAlpha(80)),
                  ),
                  child: Column(
                    children: [
                      _sumRow(
                          s.isArabic ? 'السعر الإجمالي' : 'Total',
                          s.isArabic ? 'يُحدد من الإدارة' : 'Set by admin',
                          AppColors.orange),
                      _sumRow(
                          s.isArabic ? 'نقاط هذه الفاتورة' : 'Invoice points',
                          '—',
                          AppColors.teal),
                      _sumRow(
                          s.isArabic ? 'الرصيد المتبقي' : 'Remaining',
                          '—',
                          AppColors.teal),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: <Color>[AppColors.orange, Color(0xFFF26B0F)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white),
                      onPressed: _busy ? null : () => _submit(),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              s.isArabic ? 'إتمام الشراء' : 'Checkout',
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
