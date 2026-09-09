import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'store_service.dart';
import 'strings.dart';

class AppSettings extends ChangeNotifier {
  bool _isDark = true;
  bool _isArabic = true;
  bool _isLoggedIn = false;
  bool _isGuest = false;
  User? _user;

  bool get isDark => _isDark;
  bool get isArabic => _isArabic;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  User? get user => _user;
  int get points => _user?.points ?? 0;

  /// استعادة الجلسة المحفوظة عند فتح التطبيق
  Future<void> restoreSession() async {
    final p = await SharedPreferences.getInstance();
    _isDark = p.getBool('isDark') ?? true;
    _isArabic = p.getBool('isArabic') ?? true;
    final type = p.getString('session_type');
    if (type == 'guest') {
      _isLoggedIn = true;
      _isGuest = true;
      _user = null;
    } else if (type == 'user') {
      final id = p.getString('session_id') ?? '';
      final users = await StoreService.loadUsers();
      for (final u in users) {
        if (u.id == id) {
          _user = u;
          _isLoggedIn = true;
          _isGuest = false;
          break;
        }
      }
      if (_user == null) {
        await p.remove('session_type');
        await p.remove('session_id');
      }
    }
    notifyListeners();
  }

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
    _isLoggedIn = true;
    _isGuest = true;
    _user = null;
    final p = await SharedPreferences.getInstance();
    await p.setString('session_type', 'guest');
    await p.remove('session_id');
    notifyListeners();
  }

  Future<void> loginAsUser(User u) async {
    _isLoggedIn = true;
    _isGuest = false;
    _user = u;
    final p = await SharedPreferences.getInstance();
    await p.setString('session_type', 'user');
    await p.setString('session_id', u.id);
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _isGuest = false;
    _user = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('session_type');
    await p.remove('session_id');
    notifyListeners();
  }

  /// تحديث بيانات المستخدم (نقاطه ورصيده) من المستودع
  Future<bool> refreshUser() async {
    if (_user == null) return false;
    final users = await StoreService.loadUsers();
    for (final u in users) {
      if (u.id == _user!.id) {
        _user = u;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  String tr(String key) => Strings.get(_isArabic, key);
}
