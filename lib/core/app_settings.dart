import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'store_service.dart';

class AppSettings extends ChangeNotifier {
  bool _isArabic = true;
  bool _isDark = false;
  bool _isImageAdmin = false;
  User? _user;

  // ===== Getters =====
  bool get isArabic => _isArabic;
  bool get isDark => _isDark;
  bool get isImageAdmin => _isImageAdmin;
  bool get isGuest => _user == null || _user!.role == 'guest';
  User? get user => _user;

  int get points => _user?.points ?? 0;
  int get stored => _user?.stored ?? 0;

  // ===== الترجمة =====
  String tr(String key) {
    final Map<String, Map<String, String>> _strings = {
      'appName': {'ar': 'شركة فاوري', 'en': 'FAWORI'},
      'settings': {'ar': 'الإعدادات', 'en': 'Settings'},
      'language': {'ar': 'اللغة', 'en': 'Language'},
      'about': {'ar': 'حول التطبيق', 'en': 'About'},
      'logout': {'ar': 'تسجيل الخروج', 'en': 'Logout'},
      'home': {'ar': 'الرئيسية', 'en': 'Home'},
      'products': {'ar': 'المنتجات', 'en': 'Products'},
      'wallet': {'ar': 'المحفظة', 'en': 'Wallet'},
      'favorites': {'ar': 'المفضلة', 'en': 'Favorites'},
      'profile': {'ar': 'ملفي', 'en': 'Profile'},
      'invoices': {'ar': 'الفواتير', 'en': 'Invoices'},
    };
    final m = _strings[key];
    if (m == null) return key;
    return _isArabic ? (m['ar'] ?? key) : (m['en'] ?? key);
  }

  // ===== التبديل =====
  void toggleLanguage() {
    _isArabic = !_isArabic;
    _savePrefs();
    notifyListeners();
  }

  void toggleDark() {
    _isDark = !_isDark;
    _savePrefs();
    notifyListeners();
  }

  void toggleImageAdmin() {
    _isImageAdmin = !_isImageAdmin;
    notifyListeners();
  }

  // ===== تسجيل الدخول =====
  Future<void> loginAsUser(User u) async {
    _user = u;
    final users = await StoreService.loadUsers();
    final i = users.indexWhere((x) => x.id == u.id);
    if (i >= 0) {
      users[i] = u;
    } else {
      users.add(u);
    }
    await StoreService.saveUsers(users);
    await _savePrefs();
    notifyListeners();
  }

  Future<void> loginAsGuest() async {
    _user = User(id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        name: 'ضيف', role: 'guest');
    await _savePrefs();
    notifyListeners();
  }

  void syncUser(User u) {
    _user = u;
    notifyListeners();
  }

  Future<void> addPoints(int delta) async {
    if (_user == null) return;
    final newPoints = _user!.points + delta;
    final newUser = User(
      id: _user!.id,
      name: _user!.name,
      role: _user!.role,
      phone: _user!.phone,
      password: _user!.password,
      points: newPoints,
      stored: _user!.stored,
    );
    _user = newUser;
    await StoreService.upsertUser(newUser);
    await _savePrefs();
    notifyListeners();
  }

  Future<void> addStored(int delta) async {
    if (_user == null) return;
    final newStored = _user!.stored + delta;
    final newUser = User(
      id: _user!.id,
      name: _user!.name,
      role: _user!.role,
      phone: _user!.phone,
      password: _user!.password,
      points: _user!.points,
      stored: newStored,
    );
    _user = newUser;
    await StoreService.upsertUser(newUser);
    await _savePrefs();
    notifyListeners();
  }

  // ===== الخروج =====
  void logout() {
    _user = null;
    _savePrefs();
    notifyListeners();
  }

  // ===== الحفظ والاستعادة =====
  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('isArabic', _isArabic);
    await p.setBool('isDark', _isDark);
    if (_user != null) {
      await p.setString('user', _user.toString());
      await p.setString('userId', _user!.id);
      await p.setString('userName', _user!.name);
      await p.setString('userRole', _user!.role);
    } else {
      await p.remove('user');
      await p.remove('userId');
      await p.remove('userName');
      await p.remove('userRole');
    }
  }

  Future<void> restoreSession() async {
    final p = await SharedPreferences.getInstance();
    _isArabic = p.getBool('isArabic') ?? true;
    _isDark = p.getBool('isDark') ?? false;
    final id = p.getString('userId');
    if (id != null && id.isNotEmpty) {
      final users = await StoreService.loadUsers();
      final found = users.where((u) => u.id == id).toList();
      if (found.isNotEmpty) {
        _user = found.first;
      } else {
        _user = User(
          id: id,
          name: p.getString('userName') ?? '',
          role: p.getString('userRole') ?? 'guest',
        );
      }
    }
    notifyListeners();
  }
}
