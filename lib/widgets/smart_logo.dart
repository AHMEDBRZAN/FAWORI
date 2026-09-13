import 'package:flutter/material.dart';
import 'fawori_logo.dart';

/// لوجو ذكي: يجرّب الأصل ثم الشبكة ثم الشعار الاحتياطي — لا يفشل أبداً
class SmartLogo extends StatelessWidget {
  final double size;
  const SmartLogo({super.key, this.size = 120});

  static const String _networkUrl =
      'https://ahmedbrzan.github.io/FAWORI/assets/assets/images/logo.webp';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/logo.webp',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.network(
            _networkUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(child: FaworiLogo(size: size * 0.5));
            },
          );
        },
      ),
    );
  }
}
