import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/app_settings.dart';
import '../core/gifts_service.dart';
import '../core/github_admin.dart';
import '../core/theme.dart';
import '../screens/admin_screen.dart' show askTokenDialog;
import 'pressable.dart';

class GiftsView extends StatefulWidget {
  const GiftsView({super.key});
  @override
  State<GiftsView> createState() => _GiftsViewState();
}

class _GiftsViewState extends State<GiftsView> {
  late Future<List<Gift>> _future = GiftsService.load();
  String _cat = 'all';

  void _reload() => setState(() => _future = GiftsService.load());

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return FutureBuilder<List<Gift>>(
      future: _future,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.orange));
        }
        final gifts = snap.data ?? [];
        final cats = [
          'all',
          ...gifts.map((g) => g.category).where((c) => c.isNotEmpty).toSet()
        ];
        final shown =
            _cat == 'all' ? gifts : gifts.where((g) => g.category == _cat).toList();
        return Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: 118,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: cats.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final c = cats[i];
                      final active = c == _cat;
                      return Pressable(
                        onTap: () => setState(() => _cat = c),
                        child: Container(
                          width: 110,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: active
                                    ? AppColors.orange
                                    : AppTheme.border(context),
                                width: active ? 1.5 : 1),
                          ),
                          child: Column(children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withAlpha(active ? 40 : 18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.redeem_rounded,
                                    color: AppColors.orange, size: 26),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(c == 'all' ? s.tr('all') : c,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: shown.isEmpty
                      ? Center(
                          child: Text(s.tr('noProducts'),
                              style: const TextStyle(color: Colors.grey)))
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.66,
                          ),
                          itemCount: shown.length,
                          itemBuilder: (_, i) => _giftCard(s, shown[i]),
                        ),
                ),
              ],
            ),
            if (s.isAdmin)
              Positioned(
                bottom: 16,
                left: 20,
                right: 20,
                child: Pressable(
                  onTap: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminGiftEditor()));
                    _reload();
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFF26B0F), AppColors.orange]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                            s.isArabic
                                ? 'إضافة هدية (مدير)'
                                : 'Add gift (admin)',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _giftCard(AppSettings s, Gift g) => Pressable(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 160,
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        g.image,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.redeem_rounded,
                                size: 60, color: AppColors.orange)),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: IconButton(
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.black26,
                          shape: const CircleBorder()),
                      icon: const Icon(Icons.favorite_border_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(g.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(g.desc,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${g.points}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppColors.orange),
                    child: const Icon(Icons.attach_money_rounded,
                        color: Colors.white, size: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
}

class AdminGiftEditor extends StatefulWidget {
  const AdminGiftEditor({super.key});
  @override
  State<AdminGiftEditor> createState() => _AdminGiftEditorState();
}

class _AdminGiftEditorState extends State<AdminGiftEditor> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _cat = TextEditingController();
  final _points = TextEditingController();
  final _price = TextEditingController();
  Uint8List? _bytes;
  bool _saving = false;

  Future<void> _pick() async {
    final f = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (f == null) return;
    final b = await f.readAsBytes();
    setState(() => _bytes = b);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final s = context.read<AppSettings>();
      var token = await GitHubAdmin.getToken();
      if (token == null || token.isEmpty) {
        token = await askTokenDialog(context, s);
        if (token == null || token.isEmpty) {
          setState(() => _saving = false);
          return;
        }
        await GitHubAdmin.saveToken(token);
      }
      String image = 'assets/images/as1.PNG';
      if (_bytes != null) {
        image = await GiftsService.uploadImage(_bytes!, token);
      }
      final gifts = await GiftsService.load();
      gifts.add(Gift(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        desc: _desc.text.trim(),
        category: _cat.text.trim(),
        image: image,
        points: int.tryParse(_points.text) ?? 0,
        price: double.tryParse(_price.text) ?? 0,
      ));
      await GiftsService.save(gifts, token);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.tr('savedRebuild'))));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _saving = false);
    }
  }

  Widget _tf(TextEditingController c, String hint, {TextInputType? keyboard}) =>
      TextField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTheme.border(context))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.teal)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Scaffold(
      appBar: AppBar(
        title: Text(s.isArabic ? 'إضافة هدية' : 'Add gift'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton(
                  icon: const Icon(Icons.check_rounded), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Pressable(
            onTap: _pick,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.orange.withAlpha(60)),
              ),
              child: _bytes == null
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.add_photo_alternate_rounded,
                              size: 40, color: AppColors.orange),
                          const SizedBox(height: 8),
                          Text(s.isArabic
                              ? 'إرفاق صورة الهدية'
                              : 'Attach gift image'),
                        ]))
                  : Center(child: Image.memory(_bytes!, fit: BoxFit.contain)),
            ),
          ),
          const SizedBox(height: 14),
          _tf(_name, s.isArabic ? 'اسم الهدية' : 'Gift name'),
          const SizedBox(height: 10),
          _tf(_desc, s.isArabic ? 'الوصف' : 'Description'),
          const SizedBox(height: 10),
          _tf(_cat, s.isArabic ? 'القسم (اختياري)' : 'Category (optional)'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _tf(_points, s.isArabic ? 'النقاط' : 'Points',
                    keyboard: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(
                child: _tf(_price,
                    s.isArabic ? 'السعر (اختياري)' : 'Price (optional)',
                    keyboard: TextInputType.number)),
          ]),
        ],
      ),
    );
  }
}
