import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'github_admin.dart';

class User {
  final String id, name, phone, password, role;
  final int points;
  User(
      {required this.id,
      required this.name,
      required this.phone,
      required this.password,
      required this.role,
      required this.points});

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id']?.toString() ?? '',
        name: j['name'] ?? '',
        phone: j['phone']?.toString() ?? '',
        password: j['password']?.toString() ?? '',
        role: j['role'] ?? 'customer',
        points: (j['points'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'phone': phone,
        'password': password, 'role': role, 'points': points,
      };
}

class InvoiceItem {
  final String name;
  final double price;
  InvoiceItem({required this.name, required this.price});
  factory InvoiceItem.fromJson(Map<String, dynamic> j) =>
      InvoiceItem(name: j['name'] ?? '', price: (j['price'] as num?)?.toDouble() ?? 0);
  Map<String, dynamic> toJson() => {'name': name, 'price': price};
}

class Invoice {
  final String id, userId, date;
  final double total;
  final int points;
  final List<InvoiceItem> items;
  Invoice(
      {required this.id,
      required this.userId,
      required this.date,
      required this.total,
      required this.points,
      required this.items});

  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
        id: j['id']?.toString() ?? '',
        userId: j['userId']?.toString() ?? '',
        date: j['date'] ?? '',
        total: (j['total'] as num?)?.toDouble() ?? 0,
        points: (j['points'] as num?)?.toInt() ?? 0,
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'userId': userId, 'date': date,
        'total': total, 'points': points,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class StoreService {
  static const usersPath = 'assets/data/users.json';
  static const invoicesPath = 'assets/data/invoices.json';

  static Future<List<User>> loadUsers() async {
    try {
      final t = await rootBundle.loadString(usersPath);
      return (jsonDecode(t) as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Invoice>> loadInvoices() async {
    try {
      final t = await rootBundle.loadString(invoicesPath);
      return (jsonDecode(t) as List<dynamic>)
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveUsers(List<User> users, String token) =>
      _put(usersPath, jsonEncode(users.map((u) => u.toJson()).toList()), token);

  static Future<void> saveInvoices(List<Invoice> list, String token) =>
      _put(invoicesPath, jsonEncode(list.map((e) => e.toJson()).toList()), token);

  static Future<void> _put(String path, String content, String token) async {
    String? sha;
    try {
      final r = await GitHubAdmin.getFile(path, token);
      sha = r.sha;
    } catch (_) {}
    final res = await http.put(
      Uri.parse(
          'https://api.github.com/repos/${GitHubAdmin.owner}/${GitHubAdmin.repo}/contents/$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
      },
      body: jsonEncode({
        'message': 'Update $path',
        'content': base64Encode(utf8.encode(content)),
        if (sha != null) 'sha': sha,
        'branch': GitHubAdmin.branch,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('PUT ${res.statusCode}');
    }
  }
}
