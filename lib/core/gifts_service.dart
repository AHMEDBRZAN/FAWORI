import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

const String kGiftsBase = 'https://ahmedbrzan.github.io/FAWORI';

class Gift {
  final String id, name, desc, category, image;
  final int points;
  final double price;

  Gift({
    required this.id,
    required this.name,
    required this.desc,
    required this.category,
    required this.image,
    required this.points,
    required this.price,
  });

  factory Gift.fromJson(Map<String, dynamic> j) => Gift(
        id: j['id']?.toString() ?? '',
        name: j['name'] ?? '',
        desc: j['desc'] ?? '',
        category: j['category'] ?? '',
        image: j['image'] ?? '',
        points: (j['points'] as num?)?.toInt() ?? 0,
        price: (j['price'] as num?)?.toDouble() ?? 0,
      );
}

class GiftsService {
  static Future<List<Gift>> loadGifts() async {
    try {
      final r = await http.get(Uri.parse(
          '$kGiftsBase/assets/assets/data/gifts.json?t=${DateTime.now().millisecondsSinceEpoch}'));
      if (r.statusCode == 200) {
        final List<dynamic> list = jsonDecode(r.body) as List<dynamic>;
        return list
            .map((e) => Gift.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    try {
      final t = await rootBundle.loadString('assets/data/gifts.json');
      final List<dynamic> list = jsonDecode(t) as List<dynamic>;
      return list
          .map((e) => Gift.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _fallback();
    }
  }

  static List<Gift> _fallback() => <Gift>[
        Gift(
            id: 'g1',
            name: 'طقم أدوات منزلية',
            desc: 'طقم متكامل عالي الجودة',
            category: 'home',
            image: 'assets/images/gift1.webp',
            points: 125000,
            price: 0),
        Gift(
            id: 'g2',
            name: 'جهاز منزلي',
            desc: 'جهاز كهربائي حديث',
            category: 'home',
            image: 'assets/images/gift2.webp',
            points: 250000,
            price: 0),
        Gift(
            id: 'g3',
            name: 'قسيمة شراء',
            desc: 'قسيمة قيّمة من متاجر فاوري',
            category: 'voucher',
            image: 'assets/images/gift3.webp',
            points: 500000,
            price: 0),
      ];
}
