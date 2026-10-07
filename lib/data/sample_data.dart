import 'catalog.dart';

class Product {
  final String id;
  final String name;
  final String brand;
  final String description;
  final String image;
  final String category;
  final int price;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    this.description = '',
    this.image = '',
    this.category = '',
    this.price = 0,
  });

  String get desc => description;

  /// ✅ نسخة محدّثة من المنتج (تُستخدم في الـ overlay)
  Product copyWith({
    String? name,
    String? description,
    String? image,
    String? category,
    int? price,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      brand: brand,
      description: description ?? this.description,
      image: image ?? this.image,
      category: category ?? this.category,
      price: price ?? this.price,
    );
  }
}

/// ============================================================
/// 🎨 طبقة التحديثات: تصحيح أسماء + أوصاف + صور للمواد المحددة
/// ============================================================
const String _imgBase =
    'https://ahmedbrzan.github.io/FAWORI/assets/images/products';

/// 🔍 البحث عن مادة بالاسم (مطابقة جزئية)
Product? _findByName(List<Product> list, String keyword) {
  for (final p in list) {
    if (p.name.contains(keyword)) return p;
  }
  return null;
}

/// ✏️ تطبيق التحديثات على الكتالوج
List<Product> _applyOverrides(List<Product> base) {
  final result = List<Product>.from(base);

  // ────────────────────────────────────────────────
  // ✅ 1) برايمر خارجي جديد 20 كغ
  // ────────────────────────────────────────────────
  final primer = _findByName(result, 'برايمر خارجي') ??
      _findByName(result, 'بريمر خارجي') ??
      _findByName(result, 'أساس بريميوم خارجي');
  if (primer != null) {
    final idx = result.indexOf(primer);
    result[idx] = primer.copyWith(
      name: 'برايمر خارجي جديد 20 كغ',
      image: '$_imgBase/primer_exterior_20kg.webp',
      description:
          'يُشكّل طبقة رابطة متينة بين الطلاء والسطح، فيزيد من قوة الالتصاق '
          'ويقلّل من استهلاك الطلاء. يتميّز بنفاذية عالية تسمح بخروج الرطوبة '
          'من داخل المبنى، ويمنع امتصاص السطح للطلاء بشكل غير متساوٍ، '
          'ليمنحك تشطيباً خارجياً متجانساً يدوم طويلاً.\n\n'
          '⏱ مدة الجفاف: 4-8 ساعات\n'
          '▦ معدل التغطية: 90-145 م²\n'
          '✨ اللمسة النهائية: طبقة واحدة\n'
          '📦 التعبئة: 20 كغم\n'
          '💧 المخفف: ماء 15%',
    );
  }

  // ────────────────────────────────────────────────
  // 🔮 أضف تحديثات جديدة هنا بنفس النمط:
  // ────────────────────────────────────────────────
  // final x = _findByName(result, 'كلمة البحث');
  // if (x != null) {
  //   final i = result.indexOf(x);
  //   result[i] = x.copyWith(
  //     name: 'الاسم الجديد',
  //     image: '$_imgBase/اسم_الملف.webp',
  //     description: 'الوصف الجديد...',
  //   );
  // }

  return result;
}

/// ✅ المتغير الأساسي — كتالوج + تحديثات
final List<Product> sampleData = _applyOverrides(buildCatalog());

/// ✅ مرادف لـ sampleData لتوافق products_screen.dart
final List<Product> sampleProducts = sampleData;
