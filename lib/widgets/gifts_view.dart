import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';

/// ✅ صفحة الهدايا: فارغة مع رسالة ترقّب متدرجة ومرتبة
class GiftsView extends StatelessWidget {
  const GiftsView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: dark
                  ? <Color>[const Color(0xFF1E1E28), const Color(0xFF26262E)]
                  : <Color>[Colors.white, const Color(0xFFFFF8F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.orange.withAlpha(60)),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withAlpha(dark ? 40 : 25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== أيقونة الهدية داخل دائرة متدرجة =====
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFFFF8C00), Color(0xFFF26B0F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withAlpha(90),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.card_giftcard_rounded,
                    color: Colors.white, size: 44),
              ),
              const SizedBox(height: 18),

              // ===== العنوان بتدرج برتقالي =====
              ShaderMask(
                shaderCallback: (Rect r) => const LinearGradient(
                        colors: <Color>[
                          AppColors.orange,
                          Color(0xFFF26B0F)
                        ]).createShader(r),
                child: Text(
                  s.isArabic ? 'ترقبوا الهدايا' : 'Gifts coming soon',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22),
                ),
              ),
              const SizedBox(height: 14),

              // ===== شارة النقاط المتدرجة =====
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      AppColors.teal.withAlpha(dark ? 60 : 35),
                      AppColors.teal.withAlpha(dark ? 25 : 15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.teal.withAlpha(90)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.teal, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      s.isArabic
                          ? 'أقل هدية بـ 15 نقطة'
                          : 'Smallest gift at 15 points',
                      style: const TextStyle(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w900,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ===== سطر تشجيعي =====
              Text(
                s.isArabic
                    ? 'اجمع نقاطك الآن واستعد للمفاجآت'
                    : 'Collect your points now and stay tuned',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
