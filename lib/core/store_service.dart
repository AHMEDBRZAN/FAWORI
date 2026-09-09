import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'password': password,
        'role': role,
        'points': points,
        'stored': stored,
      };
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
  static Future<List<User>> loadUsers() async {
    try {
      final t = await rootBundle.loadString('assets/data/users.json');
      return (jsonDecode(t) as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Invoice>> loadInvoices() async {
    try {
      final t = await rootBundle.loadString('assets/data/invoices.json');
      return (jsonDecode(t) as List<dynamic>)
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// إنشاء مستخدم جديد وحفظه في المستودع (يُستخدم من تطبيق الكمبيوتر فقط)
  /// من الجوال: لا يمكن الكتابة للمستودع مباشرة (يحتاج GitHub API)
  static Future<bool> createUserLocally({
    required String phone,
    required String password,
    required String role,
  }) async {
    // هذه الدالة تعمل محلياً فقط - التطبيق الجوال يقرأ فقط
    // الإنشاء الفعلي يكون من لوحة الكمبيوتر
    return false;
  }
}
