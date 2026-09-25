import 'catalog.dart';

class Product {
  final String id;
  final String name;
  final String brand;
  final String description;
  final String image;
  final String category;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    this.description = '',
    this.image = '',
    this.category = '',
  });

  String get desc => description;
}

/// ✅ المتغير الأساسي - يُبنى من الكتالوج الكامل (688 مادة)
final List<Product> sampleData = buildCatalog();

/// ✅ مرادف لـ sampleData لتوافق products_screen.dart
final List<Product> sampleProducts = sampleData;
