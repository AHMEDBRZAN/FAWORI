class Product {
  final String id, name, desc, brand, category;
  const Product(this.id, this.name, this.desc, this.brand, this.category);
}

const sampleProducts = [
  Product('1', 'طلاء كوزمك داخلي', 'طلاء داخلي مائي ذو ملمس حريري وتشطيب فائق النعومة', 'fawori', 'interior'),
  Product('2', 'طلاء فينومين خارجي', 'طلاء خارجي مرن مصنوع من مستحلب أكريليكي نقي', 'fawori', 'exterior'),
  Product('3', 'أساس سونيوم أبيض', 'أساس أكريليكي عالي الجودة للأسطح الداخلية', 'fawori', 'primers'),
  Product('4', 'أساس برو أستر', 'أساس سيليكوني لتعزيز الالتصاق', 'fawori', 'primers'),
  Product('5', 'طلاء سيليكوني مط', 'طلاء داخلي سيليكوني مقاوم للغسيل', 'fawori', 'interior'),
  Product('6', 'رغوة البولي يوريثان', 'رغوة تركيب وتثبيت متعددة الاستخدامات', 'fawori', 'exterior'),
];
