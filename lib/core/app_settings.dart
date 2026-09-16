import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'messenger.dart';
import 'orders_service.dart';
import 'store_service.dart';

class AppSettings extends ChangeNotifier {
  bool _isArabic = true;
  bool _isDark = false;
  bool _isImageAdmin = false;
  User? _user;

  Timer? _pollTimer;
  int _lastPending = -1;
  int _ordersVersion = 0;
  String _lastSig = '';
  int pendingCount = 0;

  // 👁️ تتبع المقروء لكل مستخدم على حدة
  Set<String> _seenIds = {};
  bool _seenLoaded = false;
  int unseenCount = 0;

  bool _listenersAttached = false;

  bool get isArabic => _isArabic;
  bool get isDark => _isDark;
  bool get isImageAdmin => _isImageAdmin;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.role == 'admin';
  bool get isGuest => _user == null || _user!.role == 'guest';
  User? get user => _user;
  int get points => _user?.points ?? 0;
  int get stored => _user?.stored ?? 0;
  int get ordersVersion => _ordersVersion;

  String get _seenKey => 'seen_${_user?.id ?? ''}';

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

  /// 🎯 الطلبات المهمة لكل دور:
  /// المدير ← المعلقة | المستخدم ← طلباته ذات الحالة النهائية
  List<String> _relevantIds(List<Order> orders) {
    if (_user == null) return const [];
    if (_user!.role == 'admin') {
      return orders
          .where((o) => o.status == 'pending')
          .map((o) => o.id)
          .toList();
    }
    return orders
        .where((o) => o.userId == _user!.id && o.status != 'pending')
        .map((o) => o.id)
        .toList();
  }

  void startOrderPolling() {
    _pollTimer?.cancel();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 20), (_) => _pollTick());

    if (!_listenersAttached) {
      _listenersAttached = true;
      html.document.addEventListener('visibilitychange', (_) {
        if (html.document.visibilityState == 'visible') _pollTick();
      });
      html.window.addEventListener('focus', (_) => _pollTick());
      html.document.addEventListener('click', (_) => _pollTick());
      html.document.addEventListener('keydown', (_) => _pollTick());
    }

    _pollTick();
  }

  Future<void> _pollTick() async {
    if (_user == null || _user!.role == 'guest') return;
    try {
      final created = await OrdersService.convertStoredToPoints(_user!.id);

      final orders = await OrdersService.loadOrders();
      final pending = orders.where((o) => o.status == 'pending').length;
      pendingCount = pending;

      // 👁️ حساب غير المقروء
      final relevant = _relevantIds(orders).toSet();
      if (!_seenLoaded) {
        _seenLoaded = true;
        final p = await SharedPreferences.getInstance();
        _seenIds = (p.getStringList(_seenKey) ?? []).toSet();
        // أول مرة: كل الموجود مقروء (لا شارة وهمية)
        if (_seenIds.isEmpty) {
          _seenIds = Set<String>.from(relevant);
          await p.setStringList(_seenKey, _seenIds.toList());
        }
      }
      unseenCount = relevant.difference(_seenIds).length;

      if (_user!.role == 'admin' &&
          _lastPending >= 0 &&
          pending > _lastPending) {
        final diff = pending - _lastPending;
        messengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(_isArabic
                ? '🔔 وصل $diff طلب جديد!'
                : '🔔 $diff new order(s)!'),
            backgroundColor: const Color(0xFFF26B0F),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ));
      }
      _lastPending = pending;

      final mine = orders
          .where((o) => o.userId == _user!.id)
          .map((o) => o.status)
          .join(',');
      final sig = '$pending|${orders.length}|$unseenCount|$mine';
      if (created || sig != _lastSig) {
        _lastSig = sig;
        _ordersVersion++;
        if (created) {
          await refreshUser();
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  /// ✅ تعليم كل الحالي كمقروء (تختفي الشارة) — للمدير والمستخدم
  Future<void> markAllSeen() async {
    if (_user == null || _user!.role == 'guest') return;
    try {
      final orders = await OrdersService.loadOrders();
      final rel = _relevantIds(orders).toSet();
      final p = await SharedPreferences.getInstance();
      final seen = (p.getStringList(_seenKey) ?? []).toSet();
      seen.addAll(rel);
      if (seen.length > 400) {
        final active = orders.map((o) => o.id).toSet();
        seen.retainWhere(active.contains);
      }
      _seenIds = seen;
      _seenLoaded = true;
      await p.setStringList(_seenKey, seen.toList());
      unseenCount = 0;
      notifyListeners();
    } catch (_) {}
  }

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
    _seenLoaded = false;
    _seenIds = {};
    try {
      await StoreService.upsertUser(u);
    } catch (_) {}
    await _savePrefs();
    startOrderPolling();
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
    _seenLoaded = false;
    _seenIds = {};
    await _savePrefs();
    startOrderPolling();
    notifyListeners();
  }

  Future<void> loginAsGuest() async {
    _user = User(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        name: 'ضيف',
        role: 'guest');
    _isImageAdmin = false;
    unseenCount = 0;
    await _savePrefs();
    notifyListeners();
  }

  Future<void> guestLogin() => loginAsGuest();

  void syncUser(User u) {
    _user = u;
    notifyListeners();
  }

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
    _pollTimer?.cancel();
    _lastPending = -1;
    _seenLoaded = false;
    _seenIds = {};
    unseenCount = 0;
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
      startOrderPolling();
    }
    notifyListeners();
  }
}
———————————-

lib/screens/orders_screen.dart :
