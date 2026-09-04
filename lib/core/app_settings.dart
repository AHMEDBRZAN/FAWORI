import 'package:flutter/material.dart';
import 'strings.dart';

class AppSettings extends ChangeNotifier {
  bool _isDark = true;
  bool _isArabic = true;
  bool _isLoggedIn = false;
  bool _isGuest = false;
  bool _isAdmin = false;

  bool get isDark => _isDark;
  bool get isArabic => _isArabic;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  bool get isAdmin => _isAdmin;

  void toggleDark() { _isDark = !_isDark; notifyListeners(); }
  void toggleLanguage() { _isArabic = !_isArabic; notifyListeners(); }

  void login() {
    _isLoggedIn = true;
    _isGuest = false;
    _isAdmin = false;
    notifyListeners();
  }

  void loginAsGuest() {
    _isLoggedIn = true;
    _isGuest = true;
    _isAdmin = false;
    notifyListeners();
  }

  void loginAsAdmin() {
    _isLoggedIn = true;
    _isGuest = false;
    _isAdmin = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _isGuest = false;
    _isAdmin = false;
    notifyListeners();
  }

  String tr(String key) => Strings.get(_isArabic, key);
}
