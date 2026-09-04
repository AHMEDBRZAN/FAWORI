import 'package:flutter/material.dart';
import 'strings.dart';

class AppSettings extends ChangeNotifier {
  bool _isDark = true;
  bool _isArabic = true;
  bool _isLoggedIn = false;

  bool get isDark => _isDark;
  bool get isArabic => _isArabic;
  bool get isLoggedIn => _isLoggedIn;

  void toggleDark() { _isDark = !_isDark; notifyListeners(); }
  void toggleLanguage() { _isArabic = !_isArabic; notifyListeners(); }
  void login() { _isLoggedIn = true; notifyListeners(); }
  void logout() { _isLoggedIn = false; notifyListeners(); }

  String tr(String key) => Strings.get(_isArabic, key);
}
