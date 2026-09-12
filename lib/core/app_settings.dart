import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'store_service.dart';
import 'strings.dart';

class AppSettings extends ChangeNotifier {
  bool _isDark = true;
  bool _isArabic = true;
  bool _isLoggedIn = false;
  bool _isGuest = false;
  bool _isImageAdmin = false;
  User? _user;

  bool get isDark => _isDark;
  bool get isArabic => _isArabic;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  bool get isImageAdmin => _isImageAdmin;
  User? get user => _user;
  int get points => _user?.points ?? 0;
  int get stored => _user?.stored ?? 0;

  Future<void> restoreSession() async {
    final p = await SharedPreferences.getInstance();
    _isDark = p.getBool('isDark') ?? true;
    _isArabic = p.getBool('isArabic') ?? true;
    final type = p.getString('session_type');
    if (type == 'guest') {
      _isLoggedIn = true; _isGuest = true; _user = null;
    } else if (type == 'user') {
      final id = p.getString('session_id') ?? '';
      final users = await StoreService.loadUsers();
      for (final u in users) {
        if (u.id == id) { _user = u; _isLoggedIn = true; _isGuest = false; break; }
      }
      if (_user == null) {
        await p.remove('session_type'); await p.remove('session_id');
      }
    }
    notifyListeners();
  }

  void syncUser(User u) { _user = u; notifyListeners(); }

  /// دخول خاص بمدير الصور فقط (لا يُحفظ كجلسة مستخدم)
  void enterImageAdmin() { _isImageAdmin = true; notifyListeners(); }
  void exitImageAdmin() { _isImageAdmin = false; notifyListeners(); }

  Future<void> toggleDark() async {
    _isDark = !_isDark;
    final p = await SharedPreferences.getInstance();
    await p.setBool('isDark', _isDark);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _isArabic = !_isArabic;
    final p = await SharedPreferences.getInstance();
    await p.setBool('isArabic', _isArabic);
    notifyListeners();
  }

  Future<void> loginAsGuest() async {
    _isLoggedIn = true; _isGuest = true; _user = null; _isImageAdmin = false;
    final p = await SharedPreferences.getInstance();
    await p.setString('session_type', 'guest');
    await p.remove('session_id');
    notifyListeners();
  }

  Future<void> loginAsUser(User u) async {
    _isLoggedIn = true; _isGuest = false; _user = u; _isImageAdmin = false;
    final p = await SharedPreferences.getInstance();
    await p.setString('session_type', 'user');
    await p.setString('session_id', u.id);
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false; _isGuest = false; _user = null; _isImageAdmin = false;
    final p = await SharedPreferences.getInstance();
    await p.remove('session_type'); await p.remove('session_id');
    notifyListeners();
  }

  String tr(String key) => Strings.get(_isArabic, key);
}
