import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final bool ar = s.isArabic;

    return Scaffold(
      backgroundColor:
          dark ? const Color(0xFF141419) : const Color(0xFFFFF8F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const SizedBox(height: 12),
          // ✅ شعار كبير بهالة + حواف متلاشية (بدون مربع حاد)
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    AppColors.orange.withAlpha(dark ? 75 : 55),
                    AppColors.orange.withAlpha(0),
                  ],
                ),
              ),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (Rect r) => const RadialGradient(
                    center: Alignment.center,
                    radius: 0.75,
                    colors: <Color>[
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: <double>[0.0, 0.70, 1.0],
                  ).createShader(r),
                  child: Image.asset(
                    'assets/images/logo.webp',
                    width: 175,
                    height: 175,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (c, o, st) => const Center(
                      child: Text('FAWORI',
                          style: TextStyle(
                              color: AppColors.orange,
                              fontSize: 30,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ShaderMask(
              shaderCallback: (Rect r) => const LinearGradient(
                      colors: <Color>[AppColors.teal, AppColors.orange])
                  .createShader(r),
              child: Text(ar ? 'شركة فاوري' : 'FAWORI Co.',
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(height: 28),
          // ✅ عنوان التعليمات
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[AppColors.orange, Color(0xFFF26B0F)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text(ar ? 'كيف تربح النقاط؟' : 'How to earn points?',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 14),
          _step(
              1,
              Icons.shopping_cart_checkout_rounded,
              AppColors.orange,
              ar ? 'اشترِ واربح' : 'Buy & earn',
              ar
                  ? 'كل عملية شراء تمنحك نقاطاً تُضاف إلى رصيدك تلقائياً.'
                  : 'Every purchase grants points added automatically.'),
          _step(
              2,
              Icons.stars_rounded,
              AppColors.teal,
              ar ? 'النقاط = رصيد' : 'Points = balance',
              ar
                  ? 'كل 125,000 د.ع = نقطة واحدة تُحفظ في محفظتك.'
                  : 'Every 125,000 IQD = 1 point stored in your wallet.'),
          _step(
              3,
              Icons.redeem_rounded,
              const Color(0xFF9B59B6),
              ar ? 'استبدل هدايا' : 'Redeem gifts',
              ar
                  ? 'استبدل نقاطك بهدايا قيّمة من كتالوج الهدايا.'
                  : 'Redeem points for valuable gifts from the catalog.'),
          _step(
              4,
              Icons.account_balance_wallet_rounded,
              const Color(0xFF0D9668),
              ar ? 'تابع فواتيرك' : 'Track invoices',
              ar
                  ? 'راجع كل فواتيرك ونقاطك ورصيدك في أي وقت.'
                  : 'Review all invoices, points and balance anytime.'),
          const SizedBox(height: 26),
          Center(
            child: Text(ar ? 'الإصدار 1.0.0' : 'Version 1.0.0',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  /// ✅ بطاقة تعليمات مرقّمة: رقم + أيقونة + عنوان + شرح
  Widget _step(int n, IconData ic, Color c, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[c.withAlpha(38), c.withAlpha(10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.withAlpha(70)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: <Color>[c, c.withAlpha(190)]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: c.withAlpha(80),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Center(
              child: Text('$n',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: c.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(ic, color: c, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: c, fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
