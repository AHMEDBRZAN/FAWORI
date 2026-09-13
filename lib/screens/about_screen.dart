import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';
import '../widgets/smart_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(s.isArabic ? 'حول التطبيق' : 'About'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const <Color>[Color(0xFF23232B), Color(0xFF2B2B34)]
                : const <Color>[Color(0xFFFFF8F1), Color(0xFFFDEFDE)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: <Color>[AppColors.orange, AppColors.teal]),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.orange.withAlpha(80),
                        blurRadius: 30,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: const SmartLogo(size: 96),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ShaderMask(
                shaderCallback: (Rect r) => const LinearGradient(
                        colors: <Color>[AppColors.orange, AppColors.teal])
                    .createShader(r),
                child: Text(
                  s.isArabic ? 'شركة فاوري' : 'FAWORI Company',
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                s.isArabic
                    ? 'وجهتك الأولى للدهانات والمواد الإنشائية'
                    : 'Your first destination for paints & building materials',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
            const SizedBox(height: 26),
            _section(
              Icons.store_rounded,
              s.isArabic ? 'من نحن' : 'Who we are',
              s.isArabic
                  ? 'شركة فاوري شركة رائدة في تجارة الدهانات والمواد الإنشائية، نجمع أبرز العلامات العالمية تحت سقف واحد لنمنحك جودة موثوقة وسعراً منافساً.'
                  : 'FAWORI is a leading trader of paints & building materials, gathering top global brands under one roof for trusted quality and fair prices.',
              AppColors.orange,
            ),
            _section(
              Icons.stars_rounded,
              s.isArabic ? 'كيف تربح النقاط' : 'How to earn points',
              s.isArabic
                  ? 'اشترِ أي منتج من شركاتنا المعتمدة، وكل 125,000 دينار من رصيدك المخزن تمنحك نقطة واحدة تلقائياً. النقاط تتراغم مع كل فاتورة.'
                  : 'Buy any product from our approved companies; every 125,000 IQD of stored balance earns you 1 point automatically. Points stack with every invoice.',
              AppColors.teal,
            ),
            _section(
              Icons.account_balance_wallet_rounded,
              s.isArabic ? 'الرصيد المخزن' : 'Stored balance',
              s.isArabic
                  ? 'كل فاتورة شراء تضيف رصيداً مخزناً يظهر في محفظتك، ويتحول تدريجياً إلى نقاط يمكنك متابعتها لحظة بلحظة.'
                  : 'Every purchase invoice adds a stored balance shown in your wallet, gradually turning into points you can track in real time.',
              const Color(0xFF9B59B6),
            ),
            _section(
              Icons.handshake_rounded,
              s.isArabic ? 'الشركات المعتمدة' : 'Approved companies',
              s.isArabic
                  ? 'فاوري، آيزومات، كادينز، سيباكس — علامات موثوقة نختارها بعناية لنضمن لك أفضل منتج وأفضل خدمة.'
                  : 'FAWORI, ISOMAT, CADENCE, SIBAX — trusted brands we carefully select to guarantee the best product and service.',
              const Color(0xFFC8961E),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _section(IconData ic, String title, String body, Color c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[c.withAlpha(30), Theme.of(context).colorScheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.withAlpha(80), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: <Color>[c, c.withAlpha(170)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(ic, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ShaderMask(
                shaderCallback: (Rect r) =>
                    LinearGradient(colors: <Color>[c, c.withAlpha(200)])
                        .createShader(r),
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.7),
          ),
        ],
      ),
    );
  }
}
