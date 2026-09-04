import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'github_admin.dart';

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'desc': desc,
        'category': category,
        'image': image,
        'points': points,
        'price': price,
      };
}

class GiftsService {
  static const String _jsonPath = 'assets/data/gifts.json';

  static Future<List<Gift>> load() async {
    try {
      final text = await rootBundle.loadString(_jsonPath);
      final List<dynamic> l = jsonDecode(text);
      return l.map((e) => Gift.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
      };

  static Future<void> save(List<Gift> gifts, String token) async {
    String? sha;
    try {
      final r = await GitHubAdmin.getFile(_jsonPath, token);
      sha = r.sha;
    } catch (_) {}
    final res = await http.put(
      Uri.parse(
          'https://api.github.com/repos/${GitHubAdmin.owner}/${GitHubAdmin.repo}/contents/$_jsonPath'),
      headers: _headers(token),
      body: jsonEncode({
        'message': 'Update gifts from admin',
        'content': base64Encode(utf8.encode(jsonEncode(gifts.map((g) => g.toJson()).toList()))),
        if (sha != null) 'sha': sha,
        'branch': GitHubAdmin.branch,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('PUT ${res.statusCode}');
    }
  }

  static Future<String> uploadImage(List<int> bytes, String token) async {
    final name = 'gift_${DateTime.now().millisecondsSinceEpoch}.png';
    final path = 'assets/images/$name';
    final res = await http.put(
      Uri.parse(
          'https://api.github.com/repos/${GitHubAdmin.owner}/${GitHubAdmin.repo}/contents/$path'),
      headers: _headers(token),
      body: jsonEncode({
        'message': 'Add gift image',
        'content': base64Encode(bytes),
        'branch': GitHubAdmin.branch,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Upload ${res.statusCode}');
    }
    return path;
  }
}
