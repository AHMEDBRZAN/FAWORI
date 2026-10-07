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

  Product copyWith({
    String? name,
    String? description,
    String? image,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      brand: brand,
      description: description ?? this.description,
      image: image ?? this.image,
      category: category,
      price: price,
    );
  }
}

///  مجلد الصور التسلسلية في المستودع
const String _imgBase = 'assets/images/products';

/// ============================================================
/// 📋 جدول التحديثات التسلسلي (سطر واحد لكل مادة):
/// [ كلمة البحث في الكتالوج , الاسم الجديد , ملف الصورة , الوصف ]
/// ✅ أي حقل تتركه فارغاً '' = لا يتغير
/// ============================================================
const List<List<String>> _updates = <List<String>>[
  [
    'برايمر خارجي',
    'برايمر خارجي جديد 20 كغ',
    'a1.webp',
    'يُشكّل طبقة رابطة متينة بين الطلاء والسطح، فيزيد من قوة الالتصاق '
        'ويقلّل من استهلاك الطلاء. يتميّز بنفاذية عالية تسمح بخروج الرطوبة '
        'من داخل المبنى، ويمنع امتصاص السطح للطلاء بشكل غير متساوٍ، '
        'ليمنحك تشطيباً خارجياً متجانساً يدوم طويلاً.\n\n'
        '⏱ مدة الجفاف: 4-8 ساعات\n'
        '▦ معدل التغطية: 90-145 م²\n'
        '✨ اللمسة النهائية: طبقة واحدة\n'
        '📦 التعبئة: 20 كغم\n'
        '💧 المخفف: ماء 15%',
  ],

  // 🔮 أضف موادك الجديدة هنا بالترتيب:
  // ['كلمة من اسم المادة', 'الاسم الجديد', 'a2.webp', 'الوصف المرتّب...'],
  // ['كلمة من اسم المادة', '', 'a3.webp', ''],   ← صورة فقط بدون تغيير اسم/وصف
];

/// 🔍 بحث جزئي بالاسم
Product? _findByName(List<Product> list, String keyword) {
  for (final p in list) {
    if (p.name.contains(keyword)) return p;
  }
  return null;
}

/// ✏️ تطبيق الجدول على الكتالوج
List<Product> _applyOverrides(List<Product> base) {
  final result = List<Product>.from(base);
  for (final u in _updates) {
    final p = _findByName(result, u[0]);
    if (p == null) continue;
    final i = result.indexOf(p);
    result[i] = p.copyWith(
      name: u[1].isEmpty ? null : u[1],
      image: u[2].isEmpty ? null : '$_imgBase/${u[2]}',
      description: u[3].isEmpty ? null : u[3],
    );
  }
  return result;
}

/// ✅ المتغير الأساسي — كتالوج 688 مادة + تحديثاتك التسلسلية
final List<Product> sampleData = _applyOverrides(buildCatalog());

/// ✅ مرادف لتوافق products_screen.dart
final List<Product> sampleProducts = sampleData;
