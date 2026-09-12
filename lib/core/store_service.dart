import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

const String kSiteBase = 'https://ahmedbrzan.github.io/FAWORI';
const String kOwner = 'AHMEDBRZAN';
const String kRepo = 'FAWORI';
const String kBranch = 'main';

/// ⚠️ ضع هنا توكن GitHub حقيقي (صلاحية repo) وإلا لن يعمل أي رفع
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
      return (jsonDecode(await _fetchRaw('users.json')) as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      try {
        final t = await rootBundle.loadString('assets/data/users.json');
        return (jsonDecode(t) as List<dynamic>)
            .map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) { return []; }
    }
  }

  static Future<List<Invoice>> loadInvoices() async {
    try {
      return (jsonDecode(await _fetchRaw('invoices.json')) as List<dynamic>)
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      try {
        final t = await rootBundle.loadString('assets/data/invoices.json');
        return (jsonDecode(t) as List<dynamic>)
            .map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) { return []; }
    }
  }
}

class ImagesService {
  static const String kImagesPath = 'assets/data/images.json';

  static Map<String, String> _h(String t) => {
        'Authorization': 'Bearer $t',
        'Accept': 'application/vnd.github+json',
        'Content-Type': 'application/json',
      };

  static String remoteUrl(String path) =>
      '$kSiteBase/assets/$path?t=${DateTime.now().millisecondsSinceEpoch}';

  static Future<Map<String, dynamic>> loadImages() async {
    try {
      final r = await http.get(Uri.parse(
          '$kSiteBase/assets/assets/data/images.json?t=${DateTime.now().millisecondsSinceEpoch}'));
      if (r.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(r.body));
    } catch (_) {}
    return {};
  }

  static Future<String?> _sha(String path, String token) async {
    final r = await http.get(
        Uri.parse('https://api.github.com/repos/$kOwner/$kRepo/contents/$path'),
        headers: _h(token));
    if (r.statusCode == 200) return jsonDecode(r.body)['sha'] as String?;
    return null;
  }

  static Future<void> putBytes(String path, List<int> bytes, String token, String msg) async {
    final sha = await _sha(path, token);
    final r = await http.put(
        Uri.parse('https://api.github.com/repos/$kOwner/$kRepo/contents/$path'),
        headers: _h(token),
        body: jsonEncode({
          'message': msg, 'content': base64Encode(bytes),
          if (sha != null) 'sha': sha, 'branch': kBranch,
        }));
    if (r.statusCode != 200 && r.statusCode != 201) throw Exception('PUT ${r.statusCode}');
  }

  static Future<void> setMapping(String section, String key, String path, String token) async {
    final sha0 = await _sha(kImagesPath, token);
    Map<String, dynamic> m = {};
    if (sha0 != null) {
      final r = await http.get(
          Uri.parse('https://api.github.com/repos/$kOwner/$kRepo/contents/$kImagesPath'),
          headers: _h(token));
      if (r.statusCode == 200) {
        final b64 = (jsonDecode(r.body)['content'] as String).replaceAll('\n', '');
        m = Map<String, dynamic>.from(jsonDecode(utf8.decode(base64Decode(b64))));
      }
    }
    final sec = Map<String, dynamic>.from(m[section] ?? {});
    sec[key] = path;
    m[section] = sec;
    final r2 = await http.put(
        Uri.parse('https://api.github.com/repos/$kOwner/$kRepo/contents/$kImagesPath'),
        headers: _h(token),
        body: jsonEncode({
          'message': 'update images.json',
          'content': base64Encode(utf8.encode(jsonEncode(m))),
          if (sha0 != null) 'sha': sha0, 'branch': kBranch,
        }));
    if (r2.statusCode != 200 && r2.statusCode != 201) throw Exception('PUT images ${r2.statusCode}');
  }
}
