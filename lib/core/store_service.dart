import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

const String kSiteBase = 'https://ahmedbrzan.github.io/FAWORI';

class User {
  final String id, name, phone, password, role;
  final int points;
  final int stored;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.password,
    required this.role,
    required this.points,
    this.stored = 0,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id']?.toString() ?? '',
        name: j['name'] ?? '',
        phone: j['phone']?.toString() ?? '',
        password: j['password']?.toString() ?? '',
        role: j['role'] ?? 'customer',
        points: (j['points'] as num?)?.toInt() ?? 0,
        stored: (j['stored'] as num?)?.toInt() ?? 0,
      );
}

class InvoiceItem {
  final String name;
  final double price;
  final int qty;
  InvoiceItem({required this.name, required this.price, this.qty = 1});
  factory InvoiceItem.fromJson(Map<String, dynamic> j) => InvoiceItem(
      name: j['name'] ?? '',
      price: (j['price'] as num?)?.toDouble() ?? 0,
      qty: (j['qty'] as num?)?.toInt() ?? 1);
}

class Invoice {
  final String id, userId, date, type;
  final double total;
  final int points;
  final int stored;
  final List<InvoiceItem> items;

  Invoice({
    required this.id,
    required this.userId,
    required this.date,
    required this.total,
    required this.points,
    required this.items,
    this.type = 'sale',
    this.stored = 0,
  });

  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
        id: j['id']?.toString() ?? '',
        userId: j['userId']?.toString() ?? '',
        date: j['date'] ?? '',
        type: j['type'] ?? 'sale',
        total: (j['total'] as num?)?.toDouble() ?? 0,
        points: (j['points'] as num?)?.toInt() ?? 0,
        stored: (j['stored'] as num?)?.toInt() ?? 0,
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class StoreService {
  static Future<String> _fetchRaw(String file) async {
    final url =
        '$kSiteBase/assets/assets/data/$file?t=${DateTime.now().millisecondsSinceEpoch}';
    final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    return r.body;
  }

  static Future<List<User>> loadUsers() async {
    try {
      final t = await _fetchRaw('users.json');
      return (jsonDecode(t) as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      try {
        final t = await rootBundle.loadString('assets/data/users.json');
        return (jsonDecode(t) as List<dynamic>)
            .map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  static Future<List<Invoice>> loadInvoices() async {
    try {
      final t = await _fetchRaw('invoices.json');
      return (jsonDecode(t) as List<dynamic>)
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      try {
        final t = await rootBundle.loadString('assets/data/invoices.json');
        return (jsonDecode(t) as List<dynamic>)
            .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }
}
