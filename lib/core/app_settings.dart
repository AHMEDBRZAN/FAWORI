import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'store_service.dart';

class AppSettings extends ChangeNotifier {
  bool _isArabic = true;
  bool _isDark = false;
  bool _isImageAdmin = false;
  User? _user;

  bool get isArabic => _isArabic;
  bool get isDark => _isDark;
  bool get isImageAdmin => _isImageAdmin;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.role == 'admin';
  bool get isGuest => _user == null || _user!.role == 'guest';
  User? get user => _user;
  int get points => _user?.points ?? 0;
  int get stored => _user?.stored ?? 0;

  String tr(String key) {
    const Map<String, Map<String, String>> strings = {
      'appName': {'ar': 'شركة فاوري', 'en': 'FAWORI'},
      'settings': {'ar': 'الإعدادات', 'en': 'Settings'},
      'language': {'ar': 'اللغة', 'en': 'Language'},
      'about': {'ar': 'حول التطبيق', 'en': 'About'},
      'logout': {'ar': 'تسجيل الخروج', 'en': 'Logout'},
      'home': {'ar': 'الرئيسية', 'en': 'Home'},
      'products': {'ar': 'المنتجات', 'en': 'Products'},
      'wallet': {'ar': 'المحفظة', 'en': 'Wallet'},
      'favorites': {'ar': 'المفضلة', 'en': 'Favorites'},
      'profile': {'ar': 'ملف الشخصي', 'en': 'Profile'},
      'invoices': {'ar': 'الفواتير', 'en': 'Invoices'},
      'gifts': {'ar': 'الهدايا', 'en': 'Gifts'},
    };
    final m = strings[key];
    if (m == null) return key;
    return _isArabic ? (m['ar'] ?? key) : (m['en'] ?? key);
  }

  /// ✅ المصدر الحقيقي للنقاط: مجموع الفواتير المقبولة للمستخدم
  Future<User> _withInvoiceTotals(User base) async {
    try {
      final invs = await StoreService.loadInvoices();
      int pts = 0;
      int st = 0;
      for (final i in invs) {
        if (i.userId == base.id) {
          pts += i.points;
          st += i.stored;
        }
      }
      return User(
        id: base.id,
        name: base.name,
        role: base.role,
        phone: base.phone,
        password: base.password,
        points: pts,
        stored: st,
      );
    } catch (_) {
      return base;
    }
  }

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

  void setImageAdmin(bool v) {
    _isImageAdmin = v;
    notifyListeners();
  }

  Future<void> loginAsUser(User u) async {
    _user = await _withInvoiceTotals(u);
    _isImageAdmin = (u.role == 'admin');
    try {
      await StoreService.upsertUser(u);
    } catch (_) {}
    await _savePrefs();
    notifyListeners();
  }

  Future<void> loginAsAdmin() async {
    final users = await StoreService.loadUsers();
    final admins = users.where((u) => u.role == 'admin').toList();
    User admin;
    if (admins.isNotEmpty) {
      admin = admins.first;
    } else {
      admin = User(
        id: 'admin_001',
        name: 'المدير',
        role: 'admin',
        phone: '0000000000',
        password: 'admin',
      );
      try {
        await StoreService.upsertUser(admin);
      } catch (_) {}
    }
    _user = await _withInvoiceTotals(admin);
    _isImageAdmin = true;
    await _savePrefs();
    notifyListeners();
  }

  Future<void> loginAsGuest() async {
    _user = User(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        name: 'ضيف',
        role: 'guest');
    _isImageAdmin = false;
    await _savePrefs();
    notifyListeners();
  }

  Future<void> guestLogin() => loginAsGuest();

  void syncUser(User u) {
    _user = u;
    notifyListeners();
  }

  /// 🔄 تحديث المستخدم: من users.json ثم مزامنة النقاط من الفواتير
  Future<void> refreshUser() async {
    if (_user == null) return;
    try {
      final users = await StoreService.loadUsers();
      final found = users.where((u) => u.id == _user!.id).toList();
      final base = found.isNotEmpty ? found.first : _user!;
      _user = await _withInvoiceTotals(base);
      await _savePrefs();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addPoints(int delta) async {
    if (_user == null) return;
    final newUser = User(
      id: _user!.id,
      name: _user!.name,
      role: _user!.role,
      phone: _user!.phone,
      password: _user!.password,
      points: _user!.points + delta,
      stored: _user!.stored,
    );
    _user = newUser;
    try {
      await StoreService.upsertUser(newUser);
    } catch (_) {}
    await _savePrefs();
    notifyListeners();
  }

  Future<void> addStored(int delta) async {
    if (_user == null) return;
    final newUser = User(
      id: _user!.id,
      name: _user!.name,
      role: _user!.role,
      phone: _user!.phone,
      password: _user!.password,
      points: _user!.points,
      stored: _user!.stored + delta,
    );
    _user = newUser;
    try {
      await StoreService.upsertUser(newUser);
    } catch (_) {}
    await _savePrefs();
    notifyListeners();
  }

  void logout() {
    _user = null;
    _isImageAdmin = false;
    _savePrefs();
    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('isArabic', _isArabic);
    await p.setBool('isDark', _isDark);
    if (_user != null) {
      await p.setString('userId', _user!.id);
      await p.setString('userName', _user!.name);
      await p.setString('userRole', _user!.role);
    } else {
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
      final base = found.isNotEmpty
          ? found.first
          : User(
              id: id,
              name: p.getString('userName') ?? '',
              role: p.getString('userRole') ?? 'guest',
            );
      _user = await _withInvoiceTotals(base);
      _isImageAdmin = (_user!.role == 'admin');
    }
    notifyListeners();
  }
}
