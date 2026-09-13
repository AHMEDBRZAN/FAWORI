import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';
import '../widgets/smart_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget _gradTitle(String t, Color c, double size) => ShaderMask(
        shaderCallback: (Rect r) =>
            LinearGradient(colors: <Color>[c, c.withAlpha(190)])
                .createShader(r),
        child: Text(t,
            style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
      );

  Widget _section(String title, Color c, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[c.withAlpha(28), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: null,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.withAlpha(80), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _gradTitle(title, c, 17),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _para(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 14, height: 1.7),
      ),
    );
  }

  Widget _step(String num, String text, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: <Color>[c, c.withAlpha(170)]),
              shape: BoxShape.circle,
            ),
            child: Text(num,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13.5, height: 1.6)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings s = context.watch<AppSettings>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> companies = <Widget>[
      _companyChip('فاوري', 'FAWORI', AppColors.orange, s),
      _companyChip('آيزومات', 'ISOMAT', const Color(0xFFE5484D), s),
      _companyChip('كادينز', 'CADENCE', const Color(0xFF9B59B6), s),
      _companyChip('سيباكس', 'SIBAX', const Color(0xFFC8961E), s),
    ];

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
          children: <Widget>[
            Center(
              child: Container(
                width: 110,
                height: 110,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(colors: <Color>[
                    AppColors.orange,
                    Color(0xFFF26B0F)
                  ]),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.orange.withAlpha(80),
                        blurRadius: 30,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: const SmartLogo(size: 110)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
                child: _gradTitle(
                    s.isArabic ? 'شركة فاوري' : 'FAWORI Company',
                    AppColors.orange,
                    24)),
            const SizedBox(height: 6),
            Center(
              child: Text(
                s.isArabic
                    ? 'وجهتك الأولى للدهان والأصباغ الأصلية'
                    : 'Your first destination for original paints',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 24),
            _section(
              s.isArabic ? 'من نحن' : 'Who we are',
              AppColors.orange,
              <Widget>[
                _para(s.isArabic
                    ? 'شركة فاوري شركة متخصصة بتجهيز الدهان والأصباغ ومواد البناء الأصلية من أبرز الوكالات العالمية. نوفر منتجات موثوقة بأسعار منافسة مع خدمة عملاء متميزة.'
                    : 'FAWORI specializes in supplying original paints, coatings and building materials from top international agencies. Trusted products, competitive prices, outstanding service.'),
              ],
            ),
            const SizedBox(height: 14),
            _section(
              s.isArabic ? 'كيف تربح النقاط؟' : 'How do you earn points?',
              AppColors.teal,
              <Widget>[
                _step('1',
                    s.isArabic
                        ? 'اشترِ أي منتج من شركاتنا المعتمدة.'
                        : 'Buy any product from our certified companies.',
                    AppColors.teal),
                _step('2',
                    s.isArabic
                        ? 'لكل فاتورة تُحتسب نقاط تلقائياً: نقطة واحدة لكل 125,000.'
                        : 'Every invoice earns points automatically: 1 point per 125,000.',
                    AppColors.teal),
                _step('3',
                    s.isArabic
                        ? 'الرصيد المتبقي يُخزَّن ويُرحَّل للفاتورة القادمة حتى تكتمل النقطة.'
                        : 'The remaining balance is stored and carried to your next invoice.',
                    AppColors.teal),
                _step('4',
                    s.isArabic
                        ? 'استبدل نقاطك بهدايا قيّمة من صفحة الهدايا.'
                        : 'Redeem your points for valuable gifts from the Gifts page.',
                    AppColors.teal),
              ],
            ),
            const SizedBox(height: 14),
            _section(
              s.isArabic ? 'الهدايا' : 'Gifts',
              const Color(0xFFE5484D),
              <Widget>[
                _para(s.isArabic
                    ? 'كلما جمعت نقاطاً أكثر فُتحت لك هدايا أكبر: أجهزة منزلية، أدوات، ومفاجآت مميزة. تابع صفحة الهدايا باستمرار.'
                    : 'The more points you collect, the bigger gifts you unlock: home appliances, tools and special surprises. Keep checking the Gifts page.'),
              ],
            ),
            const SizedBox(height: 14),
            _section(
              s.isArabic ? 'الشركات المعتمدة' : 'Certified companies',
              const Color(0xFFC8961E),
              <Widget>[
                Wrap(spacing: 8, runSpacing: 8, children: companies),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                s.isArabic ? 'الإصدار 1.0.0' : 'Version 1.0.0',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _companyChip(String ar, String en, Color c, AppSettings s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: <Color>[c, c.withAlpha(170)]),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        s.isArabic ? ar : en,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
      ),
    );
  }
}
