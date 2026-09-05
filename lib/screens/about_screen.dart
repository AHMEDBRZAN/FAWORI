import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final ar = s.isArabic;
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'حول التطبيق' : 'About'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Column(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset('assets/images/logo.png',
                    width: 140, height: 140, fit: BoxFit.cover),
              ),
              const SizedBox(height: 14),
              Text(
                ar ? 'شركة فاوري | Fawori Company' : 'Fawori Company',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.orange),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _p(ar
                    ? 'تطبيق شركة فاوري هو منصّتك الذكية التي تسهّل عليك كل شيء!'
                    : 'Fawori Company app is your smart platform that makes everything easy!'),
                _p(ar
                    ? 'سوّيناه حتى نخلي شغلك أسهل، أرباحك أكثر، وتعاملك أسرع!'
                    : 'We built it to make your work easier, your profits bigger, and your experience faster!'),
                const SizedBox(height: 6),
                _bullet(
                    ar ? 'اشترِ، جمّع، واربح!' : 'Buy, collect, and win!',
                    ar
                        ? 'كل عملية شراء من منتجات فاوري تعطيك نقاط، وكل نقطة تقرّبك من هدية مميزة!'
                        : 'Every purchase of Fawori products gives you points, and every point brings you closer to a special gift!'),
                _bullet(
                    ar ? 'هدايا على كيفك!' : 'Gifts your way!',
                    ar
                        ? 'من أدوات احترافية، إلى خصومات وهدايا حصرية، كل شيء موجود بانتظارك!'
                        : 'From professional tools to exclusive discounts and gifts, everything is waiting for you!'),
                _bullet(
                    ar ? 'تواصل سريع وسهل' : 'Fast and easy support',
                    ar
                        ? 'أي استفسار أو مشكلة تواجهك، فريق الدعم موجود بخدمتك من خلال التطبيق.'
                        : 'Any question or problem, our support team is here for you through the app.'),
                _bullet(
                    ar ? 'أنت المميز ويانه!' : 'You are special to us!',
                    ar
                        ? 'كل عميل يتعامل ويانه له مكانة خاصة، ونظام النقاط معمول حتى نكافئك ونقدّر تعبك.'
                        : 'Every customer has a special place with us, and the points system is made to reward you.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _p(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(t,
            style: TextStyle(
                color: Colors.grey.shade400, fontSize: 15, height: 1.7)),
      );

  Widget _bullet(String title, String desc) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xFFF26B0F))),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16))),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 16),
              child: Text(desc,
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 14, height: 1.7)),
            ),
          ],
        ),
      );
}
