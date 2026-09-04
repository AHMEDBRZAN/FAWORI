import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GitHubAdmin {
  static const String owner = 'AHMEDBRZAN';
  static const String repo = 'FAWORI';
  static const String branch = 'main';
  static const _tokenKey = 'gh_token';

  static const List<String> files = [
    'pubspec.yaml',
    'lib/main.dart',
    'lib/core/theme.dart',
    'lib/core/app_settings.dart',
    'lib/core/favorites.dart',
    'lib/core/strings.dart',
    'lib/core/locked_dialog.dart',
    'lib/core/github_admin.dart',
    'lib/data/sample_data.dart',
    'lib/widgets/fawori_logo.dart',
    'lib/widgets/bottom_nav.dart',
    'lib/screens/main_screen.dart',
    'lib/screens/home_screen.dart',
    'lib/screens/products_screen.dart',
    'lib/screens/settings_screen.dart',
    'lib/screens/simple_screens.dart',
    'lib/screens/login_screen.dart',
    'lib/screens/admin_screen.dart',
    'web/index.html',
    'web/manifest.json',
    '.github/workflows/deploy.yml',
  ];

  static Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_tokenKey);
  }

  static Future<void> saveToken(String t) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_tokenKey, t);
  }

  static Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
      };

  static Future<({String content, String sha})> getFile(String path, String token) async {
    final res = await http.get(
      Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path?ref=$branch'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception('GET ${res.statusCode}');
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final b64 = (j['content'] as String).replaceAll('\n', '');
    return (content: utf8.decode(base64Decode(b64)), sha: j['sha'] as String);
  }

  static Future<void> putFile(String path, String content, String sha, String token) async {
    final res = await http.put(
      Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path'),
      headers: _headers(token),
      body: jsonEncode({
        'message': 'Update $path from admin panel',
        'content': base64Encode(utf8.encode(content)),
        'sha': sha,
        'branch': branch,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('PUT ${res.statusCode}');
    }
  }
}
