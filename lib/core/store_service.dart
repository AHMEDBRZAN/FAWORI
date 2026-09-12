import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

const String kSiteBase = 'https://ahmedbrzan.github.io/FAWORI';
const String kOwner = 'AHMEDBRZAN';
const String kRepo = 'FAWORI';
const String kBranch = 'main';

/// ضع هنا توكن GitHub صحيح (صلاحية repo) كاحتياط، أو اتركه وأدخله من التطبيق
const String kUploadToken = 'PASTE_YOUR_GITHUB_TOKEN_HERE';

class User {
  final String id, name, phone, password, role;
  final int points;
  final int stored;
  User({required this.id, required this.name, required this.phone,
      required this.password, required this.role,
      required this.points, this.stored = 0});
  factory User.fromJson(Map<String, dynamic> j) => User(
      id: j['id']?.toString() ?? '', name: j['name'] ?? '',
      phone: j['phone']?.toString() ?? '', password: j['password'] ?? '',
      role: j['role'] ?? 'customer',
      points: (j['points'] as num?)?.toInt() ?? 0,
      stored: (j['stored'] as num?)?.toInt() ?? 0);
}

class InvoiceItem {
  final String name; final double price; final int qty;
  InvoiceItem({required this.name, required this.price, this.qty = 1});
  factory InvoiceItem.fromJson(Map<String, dynamic> j) => InvoiceItem(
      name: j['name'] ?? '', price: (j['price'] as num?)?.toDouble() ?? 0,
      qty: (j['qty'] as num?)?.toInt() ?? 1);
}

class Invoice {
  final String id, userId, date, type, no;
  final double total; final int points; final int stored;
  final List<InvoiceItem> items;
  Invoice({required this.id, required this.userId, required this.date,
      required this.total, required this.points, required this.items,
      this.type = 'sale', this.stored = 0, this.no = ''});
  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
      id: j['id']?.toString() ?? '', userId: j['userId']?.toString() ?? '',
      date: j['date'] ?? '', type: j['type'] ?? 'sale',
      no: j['no']?.toString() ?? '',
      total: (j['total'] as num?)?.toDouble() ?? 0,
      points: (j['points'] as num?)?.toInt() ?? 0,
      stored: (j['stored'] as num?)?.toInt() ?? 0,
      items: (j['items'] as List<dynamic>? ?? [])
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>)).toList());
}

class StoreService {
  static Future<String> _fetchRaw(String file) async {
    final r = await http.get(Uri.parse(
        '$kSiteBase/assets/assets/data/$file?t=${DateTime.now().millisecondsSinceEpoch}'));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    return r.body;
  }

  static Future<List<User>> loadUsers() async {
    try {
      final List<dynamic> list =
          jsonDecode(await _fetchRaw('users.json')) as List<dynamic>;
      return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      try {
        final t = await rootBundle.loadString('assets/data/users.json');
        final List<dynamic> list = jsonDecode(t) as List<dynamic>;
        return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        return [];
      }
    }
  }

  static Future<List<Invoice>> loadInvoices() async {
    try {
      final List<dynamic> list =
          jsonDecode(await _fetchRaw('invoices.json')) as List<dynamic>;
      return list.map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      try {
        final t = await rootBundle.loadString('assets/data/invoices.json');
        final List<dynamic> list = jsonDecode(t) as List<dynamic>;
        return list.map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        return [];
      }
    }
  }
}

class ImagesService {
  static const String kImagesPath = 'assets/data/images.json';
  static String? _memToken;

  static Map<String, String> _h(String t) {
    return {
      'Authorization': 'Bearer $t',
      'Accept': 'application/vnd.github+json',
      'Content-Type': 'application/json',
    };
  }

  static String remoteUrl(String path) {
    return '$kSiteBase/assets/$p?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<String> resolveToken() async {
    if (_memToken != null && _memToken!.isNotEmpty) return _memToken!;
    if (kUploadToken.isNotEmpty && kUploadToken != 'PASTE_YOUR_GITHUB_TOKEN_HERE') {
      return kUploadToken;
    }
    return '';
  }

  static Future<String?> askGitHubToken(BuildContext context) async {
    final c = TextEditingController();
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF23232B),
        title: const Text('توكن GitHub', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: c,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              hintText: 'ghp_...', hintStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('حفظ')),
        ],
      ),
    );
    if (r != null && r.isNotEmpty) {
      _memToken = r;
      return r;
    }
    return null;
  }

  static Future<Map<String, dynamic>> loadImages() async {
    try {
      final r = await http.get(Uri.parse(
          '$kSiteBase/assets/assets/data/images.json?t=${DateTime.now().millisecondsSinceEpoch}'));
      if (r.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(r.body));
      }
    } catch (_) {}
    return {};
  }

  static Future<String?> _sha(String path, String token) async {
    final r = await http.get(
        Uri.parse('https://api.github.com/repos/$kOwner/$kRepo/contents/$path'),
        headers: _h(token));
    if (r.statusCode == 200) {
      return jsonDecode(r.body)['sha'] as String?;
    }
    return null;
  }

  static Future<void> putBytes(
      String path, List<int> bytes, String token, String msg) async {
    String tk = token;
    if (tk.isEmpty || tk == 'PASTE_YOUR_GITHUB_TOKEN_HERE') {
      tk = await resolveToken();
    }
    if (tk.isEmpty) throw Exception('لا يوجد توكن GitHub — أدخله أولاً');

    final sha = await _sha(path, tk);
    final Map<String, dynamic> body = {
      'message': msg,
      'content': base64Encode(bytes),
      'branch': kBranch,
    };
    if (sha != null) body['sha'] = sha;

    final r = await http.put(
        Uri.parse('https://api.github.com/repos/$kOwner/$kRepo/contents/$path'),
        headers: _h(tk),
        body: jsonEncode(body));

    if (r.statusCode == 401) throw Exception('401: التوكن غير صالح');
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('PUT ${r.statusCode}');
    }
  }

  static Future<void> setMapping(
      String section, String key, String path, String token) async {
    String tk = token;
    if (tk.isEmpty || tk == 'PASTE_YOUR_GITHUB_TOKEN_HERE') {
      tk = await resolveToken();
    }
    if (tk.isEmpty) throw Exception('لا يوجد توكن GitHub — أدخله أولاً');

    final sha0 = await _sha(kImagesPath, tk);
    Map<String, dynamic> m = {};
    if (sha0 != null) {
      final r = await http.get(
          Uri.parse(
              'https://api.github.com/repos/$kOwner/$kRepo/contents/$kImagesPath'),
          headers: _h(tk));
      if (r.statusCode == 200) {
        final b64 = (jsonDecode(r.body)['content'] as String).replaceAll('\n', '');
        m = Map<String, dynamic>.from(jsonDecode(utf8.decode(base64Decode(b64))));
      }
    }

    final sec = Map<String, dynamic>.from(m[section] ?? {});
    sec[key] = path;
    m[section] = sec;

    final Map<String, dynamic> body2 = {
      'message': 'update images.json',
      'content': base64Encode(utf8.encode(jsonEncode(m))),
      'branch': kBranch,
    };
    if (sha0 != null) body2['sha'] = sha0;

    final r2 = await http.put(
        Uri.parse('https://api.github.com/repos/$kOwner/$kRepo/contents/$kImagesPath'),
        headers: _h(tk),
        body: jsonEncode(body2));

    if (r2.statusCode == 401) throw Exception('401: التوكن غير صالح');
    if (r2.statusCode != 200 && r2.statusCode != 201) {
      throw Exception('PUT images ${r2.statusCode}');
    }
  }
}
