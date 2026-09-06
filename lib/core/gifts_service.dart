import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

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
  static Future<List<Gift>> load() async {
    try {
      final text = await rootBundle.loadString('assets/data/gifts.json');
      final List<dynamic> l = jsonDecode(text);
      return l.map((e) => Gift.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
