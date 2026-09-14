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
}

/// ✅ المتغير المصدَّر الذي يستخدمه FavoritesScreen
final List<Product> sampleData = const <Product>[
  // ===== فاوري FAWORI =====
  Product(
    id: 'faw_001',
    name: 'دهان داخلي فاوري مات',
    brand: 'fawori',
    description: 'دهان داخلي مات عالي الجودة',
    category: 'interior',
  ),
  Product(
    id: 'faw_002',
    name: 'دهان فاوري لامع',
    brand: 'fawori',
    description: 'دهان خارجي لامع مقاوم للعوامل الجوية',
    category: 'exterior',
  ),
  Product(
    id: 'faw_003',
    name: 'أساس فاوري',
    brand: 'fawori',
    description: 'أساس تحضيري للأسطح',
    category: 'primer',
  ),

  // ===== آيزومات ISOMAT =====
  Product(
    id: 'iso_001',
    name: 'عازل مائي آيزومات',
    brand: 'isomat',
    description: 'عازل مائي للأسطح والحمامات',
    category: 'waterproof',
  ),
  Product(
    id: 'iso_002',
    name: 'مانع تسرب آيزومات',
    brand: 'isomat',
    description: 'مانع تسرب للمفاصل والشقوق',
    category: 'sealant',
  ),
  Product(
    id: 'iso_003',
    name: 'لاصق سيراميك آيزومات',
    brand: 'isomat',
    description: 'لاصق سيراميك عالي القوة',
    category: 'adhesive',
  ),

  // ===== كادينز CADENCE =====
  Product(
    id: 'cad_001',
    name: 'دهان كادينز أكريليك',
    brand: 'cadence',
    description: 'دهان أكريليك متعدد الاستخدامات',
    category: 'acrylic',
  ),
  Product(
    id: 'cad_002',
    name: 'ورنيش كادينز',
    brand: 'cadence',
    description: 'ورنيش حماية للأسطح الخشبية',
    category: 'varnish',
  ),
  Product(
    id: 'cad_003',
    name: 'صبغة كادينز',
    brand: 'cadence',
    description: 'صبغة تلوين للأعمال الفنية',
    category: 'pigment',
  ),

  // ===== سيباكس SIBAX =====
  Product(
    id: 'sib_001',
    name: 'معجون سيباكس',
    brand: 'sibax',
    description: 'معجون جدران للتمليس',
    category: 'putty',
  ),
  Product(
    id: 'sib_002',
    name: 'دهان سيباكس خارجي',
    brand: 'sibax',
    description: 'دهان خارجي مقاوم',
    category: 'exterior',
  ),
  Product(
    id: 'sib_003',
    name: 'أساس سيباكس',
    brand: 'sibax',
    description: 'أساس تحضيري متعدد الأغراض',
    category: 'primer',
  ),
];
