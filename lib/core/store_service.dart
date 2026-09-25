import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _raw = 'https://raw.githubusercontent.com/AHMEDBRZAN/FAWORI/main';
const String _site = 'https://ahmedbrzan.github.io/FAWORI';
const String kWriteProxy = 'https://fawori.ahmdkaka1997.workers.dev/put';

class User {
  final String id;
  String name;
  String phone;
  String password;
  String role;
  int points;
  int stored;

  User({
    required this.id,
    required this.name,
    this.phone = '',
    this.password = '',
    required this.role,
    this.points = 0,
    this.stored = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'password': password,
        'role': role,
        'points': points,
        'stored': stored,
      };

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: '${j['id'] ?? ''}',
        name: '${j['name'] ?? ''}',
        phone: '${j['phone'] ?? ''}',
        password: '${j['password'] ?? ''}',
        role: '${j['role'] ?? 'client'}',
        points: (j['points'] as num?)?.toInt() ?? 0,
        stored: (j['stored'] as num?)?.toInt() ?? 0,
      );
}

class InvoiceItem {
  final String name;
  final int qty;
  final int price;

  InvoiceItem({required this.name, this.qty = 1, this.price = 0});

  Map<String, dynamic> toJson() => {'name': name, 'qty': qty, 'price': price};

  factory InvoiceItem.fromJson(Map<String, dynamic> j) => InvoiceItem(
        name: '${j['name'] ?? ''}',
        qty: (j['qty'] as num?)?.toInt() ?? 1,
        price: (j['price'] as num?)?.toInt() ?? 0,
      );
}

class Invoice {
  final String id;
  final String userId;
  final String date;
  final String type;
  String no;
  double total;
  int points;
  int stored;
  final List<InvoiceItem> items;

  Invoice({
    required this.id,
    required this.userId,
    required this.date,
    this.type = 'sale',
    this.no = '',
    this.total = 0,
    this.points = 0,
    this.stored = 0,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'date': date,
        'type': type,
        'no': no,
        'total': total,
        'points': points,
        'stored': stored,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
        id: '${j['id'] ?? ''}',
        userId: '${j['userId'] ?? ''}',
        date: '${j['date'] ?? ''}',
        type: '${j['type'] ?? 'sale'}',
        no: '${j['no'] ?? ''}',
        total: (j['total'] as num?)?.toDouble() ?? 0,
        points: (j['points'] as num?)?.toInt() ?? 0,
        stored: (j['stored'] as num?)?.toInt() ?? 0,
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class StoreService {
  static Future<dynamic> _fetchJson(String path) async {
    try {
      final r = await http
          .get(Uri.parse(
              '$_raw/$path?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (_) {}
    try {
      final r = await http
          .get(Uri.parse(
              '$_site/$path?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (_) {}
    return [];
  }

  static Future<List<User>> loadUsers() async {
    final d = await _fetchJson('assets/data/users.json');
    final list = <User>[];
    if (d is List) {
      for (final e in d) {
        list.add(User.fromJson(e as Map<String, dynamic>));
      }
    }
    if (!list.any((u) => u.id == 'ctrl')) {
      list.add(User.fromJson({
        'id': 'ctrl',
        'name': 'المتحكم',
        'phone': '19972000',
        'password': 'ad',
        'role': 'admin',
        'points': 0,
        'stored': 0,
      }));
    }
    return list;
  }

  static Future<List<Invoice>> loadInvoices() async {
    final d = await _fetchJson('assets/data/invoices.json');
    if (d is List) {
      return d
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<void> addUserRaw(Map<String, dynamic> entry) async {
    final users = await _fetchJson('assets/data/users.json');
    if (users is List) {
      users.add(entry);
      await _putJson('assets/data/users.json', users);
    } else {
      await _putJson('assets/data/users.json', [entry]);
    }
  }

  static Future<void> patchUser(
      String id, Map<String, dynamic> patch) async {
    final users = await _fetchJson('assets/data/users.json');
    if (users is List) {
      final i = users.indexWhere((u) => u is Map && u['id'] == id);
      if (i >= 0) {
        final m = Map<String, dynamic>.from(users[i] as Map);
        m.addAll(patch);
        users[i] = m;
        await _putJson('assets/data/users.json', users);
      }
    }
  }

  static Future<void> upsertUser(User u) async {
    final users = await _fetchJson('assets/data/users.json');
    final list = users is List
        ? List<Map<String, dynamic>>.from(users)
        : <Map<String, dynamic>>[];
    final i = list.indexWhere((x) => x['id'] == u.id);
    final map = u.toJson();
    if (i >= 0) {
      list[i] = map;
    } else {
      list.add(map);
    }
    await _putJson('assets/data/users.json', list);
  }

  static Future<void> _putJson(String path, dynamic data) async {
    final r = await http.post(
      Uri.parse(kWriteProxy),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'path': path,
        'content': base64Encode(utf8.encode(jsonEncode(data))),
      }),
    );
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('PUT ${r.statusCode}');
    }
  }
}

class ImagesService {
  static const String _tokenKey = 'gh_token';

  static Future<String> resolveToken() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString(_tokenKey);
    if (t != null && t.isNotEmpty) return t;
    return '';
  }

  static Future<void> saveToken(String t) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_tokenKey, t);
  }

  static Future<String?> askGitHubToken(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.key_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text('GitHub Token',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'ghp_...',
            filled: true,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () async {
              final t = ctrl.text.trim();
              if (t.isEmpty) return;
              await saveToken(t);
              Navigator.pop(ctx, t);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static Future<void> putBytes(
      String path, List<int> bytes, String token, String message) async {
    final r = await http.post(
      Uri.parse(kWriteProxy),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'path': path,
        'content': base64Encode(bytes),
        'message': message,
        'token': token,
      }),
    );
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('PUT ${r.statusCode}');
    }
  }

  static Future<void> setMapping(
      String group, String key, String path, String token) async {
    final cur = await StoreService._fetchJson('assets/data/images.json');
    final m =
        cur is Map ? Map<String, dynamic>.from(cur) : <String, dynamic>{};
    final g = m[group] is Map
        ? Map<String, dynamic>.from(m[group] as Map)
        : <String, dynamic>{};
    g[key] = path;
    m[group] = g;
    final r = await http.post(
      Uri.parse(kWriteProxy),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'path': 'assets/data/images.json',
        'content': base64Encode(utf8.encode(jsonEncode(m))),
        'token': token,
      }),
    );
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('PUT ${r.statusCode}');
    }
  }
}
