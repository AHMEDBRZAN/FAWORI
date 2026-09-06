import 'package:flutter/material.dart';
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

  void toggleDark() { _isDark = !_isDark; notifyListeners(); }
  void toggleLanguage() { _isArabic = !_isArabic; notifyListeners(); }

  void loginAsGuest() {
    _isLoggedIn = true; _isGuest = true; _user = null;
    notifyListeners();
  }

  void loginAsUser(User u) {
    _isLoggedIn = true; _isGuest = false; _user = u;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false; _isGuest = false; _user = null;
    notifyListeners();
  }

  String tr(String key) => Strings.get(_isArabic, key);
}
