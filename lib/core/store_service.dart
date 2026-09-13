import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String kOwner = 'AHMEDBRZAN';
const String kRepo = 'FAWORI';
const String kBranch = 'main';
const String kSite = 'https://ahmedbrzan.github.io/FAWORI';

/// 🔐 وسيط الكتابة (Cloudflare Worker) — التوكن عنده وليس عندنا
const String kWriteProxy = 'https://fawori.ahmdkaka1997.workers.dev/put';

/// يُترك فارغاً — لم نعد نحتاج توكن مدمجاً
const String kUploadToken = '';

class User {
  final String id, name, role;
  final double points, stored;
  User(
      {required this.id,
      required this.name,
      required this.role,
      this.points = 0,
      this.stored = 0});
  factory User.fromJson(Map<String, dynamic> j) => User(
      id: j['id'] ?? '',
      name: j['name'] ?? '',
      role: j['role'] ?? 'guest',
      points: (j['points'] as num?)?.toDouble() ?? 0,
      stored: (j['stored'] as num?)?.toDouble() ?? 0);
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'role': role, 'points': points, 'stored': stored};
}

class Invoice {
  final String id, userId, date, type, no;
  final double total, points, stored;
  final List<Map<String, dynamic>> items;
  Invoice({
    required this.id,
    required this.userId,
    required this.date,
    required this.type,
    required this.no,
    this.total = 0,
    this.points = 0,
    this.stored = 0,
    this.items = const [],
  });
  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
        id: j['id'] ?? '',
        userId: j['userId'] ?? '',
        date: j['date'] ?? '',
        type: j['type'] ?? 'sale',
        no: j['no'] ?? '',
        total: (j['total'] as num?)?.toDouble() ?? 0,
        points: (j['points'] as num?)?.toDouble() ?? 0,
        stored: (j['stored'] as num?)?.toDouble() ?? 0,
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'date': date,
        'type': type,
        'no': no,
        'total': total,
        'points': points,
        'stored': stored,
        'items': items,
      };
}

/// للإشارات القديمة في الكود (alias)
class UserInfo {
  final String id, name, role;
  final double points, stored;
  UserInfo(
      {required this.id,
      required this.name,
      required this.role,
      this.points = 0,
      this.stored = 0});
  factory UserInfo.fromJson(Map<String, dynamic> j) => UserInfo(
      id: j['id'] ?? '',
      name: j['name'] ?? '',
      role: j['role'] ?? 'guest',
      points: (j['points'] as num?)?.toDouble() ?? 0,
      stored: (j['stored'] as num?)?.toDouble() ?? 0);
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'role': role, 'points': points, 'stored': stored};
}

/// ✍️ خدمة الكتابة عبر الوسيط — بدون أي توكن
Future<void> _putViaProxy(String path, dynamic data) async {
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

Future<dynamic> _fetchJson(String path) async {
  try {
    final r = await http.get(Uri.parse(
        '$kSite/assets/$path?t=${DateTime.now().millisecondsSinceEpoch}'));
    if (r.statusCode == 200) return jsonDecode(r.body);
  } catch (_) {}
  return [];
}

class StoreService {
  static Future<List<User>> loadUsers() async {
    final d = await _fetchJson('assets/data/users.json');
    if (d is List) {
      return d.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<void> saveUsers(List<User> users) async {
    await _putViaProxy('assets/data/users.json', users.map((e) => e.toJson()).toList());
  }

  static Future<void> upsertUser(User u) async {
    final list = await loadUsers();
    final i = list.indexWhere((x) => x.id == u.id);
    if (i >= 0) {
      list[i] = u;
    } else {
      list.add(u);
    }
    await saveUsers(list);
  }

  static Future<List<Invoice>> loadInvoices() async {
    final d = await _fetchJson('assets/data/invoices.json');
    if (d is List) {
      return d.map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<void> saveInvoices(List<Invoice> invs) async {
    await _putViaProxy('assets/data/invoices.json', invs.map((e) => e.toJson()).toList());
  }

  static Future<void> addInvoice(Invoice inv) async {
    final list = await loadInvoices();
    list.add(inv);
    await saveInvoices(list);
  }
}

class ImagesService {
  static String? _memToken;

  static String remoteUrl(String path) => '$kSite/assets/$path';

  static Future<String> resolveToken() async {
    if (_memToken != null && _memToken!.isNotEmpty) return _memToken!;
    return kUploadToken;
  }

  static Future<String?> getToken() async => _memToken;

  static Future<String?> askGitHubToken(BuildContext context) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('توكن GitHub'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: 'ghp_...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              _memToken = c.text.trim();
              Navigator.pop(ctx, _memToken);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  static Future<Map<String, dynamic>> loadImages() async {
    try {
      final r = await http.get(Uri.parse(
          '${remoteUrl('assets/data/images.json')}?t=${DateTime.now().millisecondsSinceEpoch}'));
      if (r.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(r.body));
      }
    } catch (_) {}
    return {};
  }

  /// ✍️ رفع بايتات عبر الوسيط — بدون أي توكن
  static Future<void> putBytes(
      String path, List<int> bytes, String token, String message) async {
    final r = await http.post(
      Uri.parse(kWriteProxy),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'path': path, 'content': base64Encode(bytes)}),
    );
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('PUT ${r.statusCode}');
    }
  }

  /// ✍️ تحديث images.json عبر الوسيط — بدون أي توكن
  static Future<void> setMapping(
      String group, String key, String path, String token) async {
    final r = await http.get(Uri.parse(
        '${remoteUrl('assets/data/images.json')}?t=${DateTime.now().millisecondsSinceEpoch}'));
    Map<String, dynamic> m = {};
    if (r.statusCode == 200) {
      try {
        m = Map<String, dynamic>.from(jsonDecode(r.body));
      } catch (_) {}
    }
    final g = Map<String, dynamic>.from(m[group] ?? {});
    g[key] = path;
    m[group] = g;
    await _putViaProxy('assets/data/images.json', m);
  }
}
