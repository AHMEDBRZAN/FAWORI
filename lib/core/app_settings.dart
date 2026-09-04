import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  bool _isDark = true;
  bool _isArabic = true;
  bool get isDark => _isDark;
  bool get isArabic => _isArabic;

  void toggleDark() { _isDark = !_isDark; notifyListeners(); }
  void toggleLanguage() { _isArabic = !_isArabic; notifyListeners(); }
}
