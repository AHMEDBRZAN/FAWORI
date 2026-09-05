import 'package:flutter/material.dart';
import 'store_service.dart';
import 'strings.dart';

class AppSettings extends ChangeNotifier {
  bool _isDark = true;
  bool _isArabic = true;
  bool _isLoggedIn = false;
  bool _isGuest = false;
  bool _isAdmin = false;
  User? _user;

  bool get isDark => _isDark;
  bool get isArabic => _isArabic;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  bool get isAdmin => _isAdmin;
  User? get user => _user;
  int get points => _user?.points ?? 0;

  void toggleDark() { _isDark = !_isDark; notifyListeners(); }
  void toggleLanguage() { _isArabic = !_isArabic; notifyListeners(); }

  void loginAsGuest() {
    _isLoggedIn = true; _isGuest = true; _isAdmin = false; _user = null;
    notifyListeners();
  }

  void loginAsAdmin() {
    _isLoggedIn = true; _isGuest = false; _isAdmin = true; _user = null;
    notifyListeners();
  }

  void loginAsUser(User u) {
    _isLoggedIn = true; _isGuest = false;
    _isAdmin = u.role == 'admin';
    _user = u;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false; _isGuest = false; _isAdmin = false; _user = null;
    notifyListeners();
  }

  String tr(String key) => Strings.get(_isArabic, key);
}
