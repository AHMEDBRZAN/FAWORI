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

class ImagesService {
  static String? _memToken;

  static String remoteUrl(String path) => '$kSite/assets/$path';

  static Future<String> resolveToken() async {
    if (_memToken != null && _memToken!.isNotEmpty) return _memToken!;
    return kUploadToken;
  }

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
    final w = await http.post(
      Uri.parse(kWriteProxy),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'path': 'assets/data/images.json',
        'content': base64Encode(utf8.encode(jsonEncode(m))),
      }),
    );
    if (w.statusCode != 200 && w.statusCode != 201) {
      throw Exception('PUT ${w.statusCode}');
    }
  }
}
