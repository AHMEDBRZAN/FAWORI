import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/store_service.dart';
import '../core/theme.dart';
import '../data/sample_data.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final bool canBuy;
  final Function(int) onAdd;
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.canBuy,
    required this.onAdd,
  });
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  bool _busy = false;
  String _desc = '';
  String _imgPath = '';

  static const String _rawBase =
      'https://raw.githubusercontent.com/AHMEDBRZAN/FAWORI/main';
  static const String _siteBase = 'https://ahmedbrzan.github.io/FAWORI';

  @override
  void initState() {
    super.initState();
    _loadExtra();
  }

  Future<dynamic> _fetchJson(String path) async {
    try {
      final r = await http
          .get(Uri.parse(
              '$_rawBase/$path?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (_) {}
    try {
      final r = await http
          .get(Uri.parse(
              '$_siteBase/$path?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (_) {}
    return null;
  }

  /// ✅ تحميل الوصف المحفوظ + صورة المنتج المرفوعة
  Future<void> _loadExtra() async {
    String desc = '';
    String img = '';
    try {
      final e = await _fetchJson('assets/data/products_extra.json');
      if (e is Map) {
        final item = e[widget.product.id];
        if (item is Map) desc = '${item['desc'] ?? ''}';
      }
    } catch (_) {}
    try {
      var m = await _fetchJson('assets/data/images.json');
      m ??= await _fetchJson('assets/assets/data/images.json');
      if (m is Map) {
        final g = m['products'];
        if (g is Map) img = '${g[widget.product.id] ?? ''}';
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _desc = desc;
        _imgPath = img;
      });
    }
  }

  /// 🛠 نافذة تعديل المنتج (للمتحكم فقط): صورة + وصف
  Future<void> _openEdit() async {
    final s = context.read<AppSettings>();
    final descCtrl = TextEditingController(text: _desc);
    List<int>? picked;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.edit_rounded, color: AppColors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s.isArabic ? 'تعديل المنتج' : 'Edit product',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== صورة المنتج =====
                InkWell(
                  onTap: () async {
                    final f = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                        maxWidth: 800);
                    if (f == null) return;
                    picked = await f.readAsBytes();
                    setSt(() {});
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    height: 130,
                    decoration: BoxDecoration(
                      color: AppColors.orange.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.orange.withAlpha(80),
                          style: BorderStyle.solid),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (picked != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(picked!,
                                fit: BoxFit.cover),
                          )
                        else if (_imgPath.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                                '$_siteBase/assets/$_imgPath',
                                fit: BoxFit.cover,
                                errorBuilder: (c, o, st) => const Icon(
                                    Icons.image_outlined,
                                    size: 40,
                                    color: AppColors.orange)),
                          )
                        else
                          const Center(
                              child: Icon(Icons.add_photo_alternate_rounded,
                                  size: 40, color: AppColors.orange)),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                color: AppColors.orange,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.photo_camera_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // ===== الوصف =====
                Text(
                    s.isArabic
                        ? (_desc.isEmpty ? 'إضافة وصف' : 'تغيير الوصف')
                        : (_desc.isEmpty ? 'Add description' : 'Change description'),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppColors.ink),
                  decoration: InputDecoration(
                    hintText: s.isArabic
                        ? 'اكتب وصف المنتج هنا...'
                        : 'Write product description...',
                    filled: true,
                    fillColor: AppColors.orange.withAlpha(12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.isArabic ? 'إلغاء' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                await _saveEdit(descCtrl.text.trim(), picked);
              },
              child: Text(s.isArabic ? 'حفظ' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// 💾 حفظ التعديلات (صورة عبر المستودع + وصف عبر products_extra.json)
  Future<void> _saveEdit(String desc, List<int>? bytes) async {
    final s = context.read<AppSettings>();
    String tk = await ImagesService.resolveToken();
    if (tk.isEmpty) {
      final t = await ImagesService.askGitHubToken(context);
      if (t == null) return;
      tk = t;
    }
    try {
      if (bytes != null) {
        final path = 'assets/images/prod_${widget.product.id}.webp';
        await ImagesService.putBytes(path, bytes, tk, 'product image');
        await ImagesService.setMapping('products', widget.product.id, path, tk);
      }
      final cur = await _fetchJson('assets/data/products_extra.json');
      final map = cur is Map ? Map<String, dynamic>.from(cur) : <String, dynamic>{};
      map[widget.product.id] = {'desc': desc};
      await ImagesService.putBytes(
          'assets/data/products_extra.json',
          utf8.encode(jsonEncode(map)),
          tk,
          'product desc ${widget.product.id}');
      if (mounted) {
        setState(() => _desc = desc);
        await _loadExtra();
        showAppSnack(context,
            s.isArabic ? 'تم حفظ تعديلات المنتج' : 'Product updated',
            color: const Color(0xFF0D9668), icon: Icons.save_rounded);
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(context, 'فشل الحفظ: $e',
            color: Colors.red, icon: Icons.error_outline_rounded);
      }
    }
  }

  /// 🛒 إضافة للسلة + خروج تلقائي بعد ثانيتين لنفس الموضع
  Future<void> _add() async {
    final s = context.read<AppSettings>();
    if (!widget.canBuy) {
      showAppSnack(context,
          s.isArabic ? 'سجّل الدخول أولاً للشراء' : 'Login first to buy',
          color: Colors.red, icon: Icons.lock_rounded);
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    await widget.onAdd(_qty);
    if (!mounted) return;
    setState(() => _busy = false);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final bool isController = s.user?.id == 'ctrl';
    final p = widget.product;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(p.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        actions: [
          if (isController)
            IconButton(
              tooltip: s.isArabic ? 'تعديل المنتج' : 'Edit product',
              icon: const Icon(Icons.edit_rounded, color: AppColors.orange),
              onPressed: _openEdit,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== صورة المنتج =====
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1E1E28) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.orange.withAlpha(50)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _imgPath.isNotEmpty
                  ? Image.network('$_siteBase/assets/$_imgPath',
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, st) =>
                          const Icon(Icons.format_paint_rounded,
                              size: 70, color: AppColors.orange))
                  : const Icon(Icons.format_paint_rounded,
                      size: 70, color: AppColors.orange),
            ),
          ),
          const SizedBox(height: 16),
          Text(p.name,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: dark ? Colors.white : AppColors.ink)),
          const SizedBox(height: 10),

          // ===== بطاقة سعر الشراء (مرتبة ومتناسقة) =====
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  AppColors.orange.withAlpha(dark ? 50 : 30),
                  AppColors.orange.withAlpha(dark ? 20 : 12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.orange.withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined,
                    color: AppColors.orange, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      s.isArabic ? 'سعر الشراء' : 'Purchase price',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: dark ? Colors.white : AppColors.ink)),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(fmtThousands(p.price),
                      style: const TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.w900,
                          fontSize: 17)),
                ),
              ],
            ),
          ),

          // ===== الوصف (إن وجد) =====
          if (_desc.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1E1E28) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.teal.withAlpha(60)),
              ),
              child: Text(_desc,
                  style: TextStyle(
                      height: 1.6,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.grey.shade200 : AppColors.ink)),
            ),
          ],
          const SizedBox(height: 10),

          // ===== شارة القسم =====
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.teal.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(p.brand,
                style: const TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
          ),
          const SizedBox(height: 18),

          // ===== الكمية =====
          if (widget.canBuy)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.orange, size: 30),
                  onPressed: () => setState(() => _qty = (_qty + 1).clamp(1, 99)),
                ),
                const SizedBox(width: 16),
                Text('$_qty',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline,
                      color: _qty > 1 ? AppColors.orange : Colors.grey,
                      size: 30),
                  onPressed: _qty > 1
                      ? () => setState(() => _qty--)
                      : null,
                ),
              ],
            ),
          const SizedBox(height: 14),

          // ===== زر الإضافة =====
          Container(
            decoration: BoxDecoration(
                gradient: const LinearGradient(colors: <Color>[
                  Color(0xFFE8A33C),
                  Color(0xFFF26B0F)
                ]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.orange.withAlpha(80),
                      blurRadius: 14,
                      offset: const Offset(0, 5)),
                ]),
            child: SizedBox(
              height: 54,
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white),
                onPressed: _busy ? null : _add,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_shopping_cart_rounded),
                label: Text(
                    s.isArabic ? 'أضف إلى السلة' : 'Add to cart',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
