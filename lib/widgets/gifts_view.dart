import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/gifts_service.dart';
import '../core/theme.dart';
import 'pressable.dart';

const String _giftBase = 'https://ahmedbrzan.github.io/FAWORI';
String _giftImg(String p) =>
    '$_giftBase/assets/$p?t=${DateTime.now().millisecondsSinceEpoch}';

class GiftsView extends StatefulWidget {
  const GiftsView({super.key});
  @override
  State<GiftsView> createState() => _GiftsViewState();
}

class _GiftsViewState extends State<GiftsView> {
  // ✅ تم التصحيح: loadGifts بدلاً من load
  late Future<List<Gift>> _future = GiftsService.loadGifts();

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String _fmt(num n) {
    final s = n.toStringAsFixed(0);
    final out = StringBuffer();
    int c = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      out.write(s[i]);
      c++;
      if (c % 3 == 0 && i != 0) out.write(',');
    }
    return out.toString().split('').reversed.join();
  }

  void _redeem(Gift g) {
    final AppSettings s = context.read<AppSettings>();
    if (s.user == null) {
      _snack('سجّل الدخول أولاً لاستبدال الهدايا');
      return;
    }
    if (s.points < g.points) {
      _snack('نقاطك غير كافية لهذه الهدية (${_fmt(g.points)} نقطة)');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(s.isArabic ? 'استبدال الهدية' : 'Redeem gift'),
        content: Text(s.isArabic
            ? 'سيتم خصم ${_fmt(g.points)} نقطة مقابل: ${g.name}'
            : 'Redeem ${g.name} for ${_fmt(g.points)} points'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.isArabic ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: () {
              Navigator.pop(ctx);
              _snack('✅ تم إرسال طلب الاستبدال، سيتم التواصل معك');
            },
            child: Text(s.isArabic ? 'تأكيد' : 'Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _card(Gift g) {
    final AppSettings s = context.watch<AppSettings>();
    final bool enough = (s.user?.points ?? 0) >= g.points;
    return Pressable(
      onTap: () => _redeem(g),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              AppColors.teal.withAlpha(25),
              Theme.of(context).colorScheme.surface
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.teal.withAlpha(70), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: AppColors.teal.withAlpha(25),
                blurRadius: 12,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(_giftImg(g.image), fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (c, o, st) => Container(
                        color: AppColors.teal.withAlpha(25),
                        child: const Center(
                            child: Icon(Icons.redeem_rounded,
                                size: 48, color: AppColors.teal)))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(children: <Widget>[
                Text(g.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: enough
                        ? AppColors.teal.withAlpha(35)
                        : Colors.red.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_fmt(g.points)} ${s.isArabic ? 'نقطة' : 'pts'}',
                    style: TextStyle(
                        color: enough ? AppColors.teal : Colors.red.shade300,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Gift>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final gifts = snap.data ?? [];
        if (gifts.isEmpty) {
          return const Center(child: Text('لا توجد هدايا حالياً'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72),
          itemCount: gifts.length,
          itemBuilder: (context, i) => _card(gifts[i]),
        );
      },
    );
  }
}
