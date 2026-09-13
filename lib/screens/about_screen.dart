import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';
import '../widgets/smart_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget _section(IconData ic, Color c, String title, String body) {
    return Builder(builder: (context) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: <Color>[
                c.withAlpha(30),
                Theme.of(context).colorScheme.surface
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.withAlpha(80), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: <Color>[c, c.withAlpha(170)]),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(ic, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (Rect r) =>
                        LinearGradient(colors: <Color>[c, c.withAlpha(190)])
                            .createShader(r),
                    child: Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Colors.white)),
                  ),
                  const SizedBox(height: 6),
                  Text(body,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings s = context.watch<AppSettings>();
    final bool ar = s.isArabic;
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'حول التطبيق' : 'About'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: SmartLogo(size: 110)),
          const SizedBox(height: 16),
          Center(
            child: ShaderMask(
              shaderCallback: (Rect r) => const LinearGradient(
                      colors: <Color>[AppColors.teal, AppColors.orange])
                  .createShader(r),
              child: Text(
                ar ? 'شركة فاوري' : 'FAWORI Company',
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              ar ? 'نظام النقاط والهدايا الذكي' : 'Smart points & rewards',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
          const SizedBox(height: 26),
          _section(
              Icons.shopping_cart_rounded,
              AppColors.orange,
              ar ? 'اشترِ واربح' : 'Buy & Earn',
              ar
                  ? 'كل عملية شراء تمنحك نقاطاً تُضاف إلى رصيدك تلقائياً.'
                  : 'Every purchase automatically earns you points.'),
          _section(
              Icons.stars_rounded,
              AppColors.teal,
              ar ? 'النقاط = رصيد' : 'Points = Balance',
              ar
                  ? 'كل 125,000 د.ع = نقطة واحدة تُحفظ في محفظتك.'
                  : 'Every 125,000 IQD = 1 point saved in your wallet.'),
          _section(
              Icons.redeem_rounded,
              const Color(0xFF9B59B6),
              ar ? 'استبدل هدايا' : 'Redeem Gifts',
              ar
                  ? 'استبدل نقاطك بهدايا قيّمة من كتالوج الهدايا.'
                  : 'Redeem your points for valuable gifts.'),
          _section(
              Icons.account_balance_wallet_rounded,
              const Color(0xFF0D9668),
              ar ? 'تابع فواتيرك' : 'Track Invoices',
              ar
                  ? 'راجع كل فواتيرك ونقاطك ورصيدك في أي وقت.'
                  : 'Review all invoices, points and balance anytime.'),
          const SizedBox(height: 24),
          Center(
              child: Text(ar ? 'الإصدار 1.0.0' : 'Version 1.0.0',
                  style: TextStyle(color: Colors.grey.shade500))),
        ],
      ),
    );
  }
}
