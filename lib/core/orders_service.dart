import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'store_service.dart';

const String _raw = 'https://raw.githubusercontent.com/AHMEDBRZAN/FAWORI/main';
const String _site = 'https://ahmedbrzan.github.io/FAWORI';
const String kOrdersPath = 'assets/data/orders.json';
const int kPointUnit = 125000;
const String kWriteProxy = 'https://fawori.ahmdkaka1997.workers.dev/put';

String fmtThousands(num n) {
  final bool neg = n < 0;
  final s = n.abs().toStringAsFixed(0);
  final out = StringBuffer();
  int c = 0;
  for (int i = s.length - 1; i >= 0; i--) {
    out.write(s[i]);
    c++;
    if (c % 3 == 0 && i != 0) out.write(',');
  }
  final res = out.toString().split('').reversed.join();
  return neg ? '-$res' : res;
}

class CartItem {
  final String id, name, image, brand;
  int qty;
  CartItem(
      {required this.id,
      required this.name,
      required this.image,
      required this.brand,
      this.qty = 1});
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'image': image, 'brand': brand, 'qty': qty};
  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
      id: j['id'] ?? '',
      name: j['name'] ?? '',
      image: j['image'] ?? '',
      brand: j['brand'] ?? '',
      qty: (j['qty'] as num?)?.toInt() ?? 1);
}

class OrderItem {
  final String name;
  final int qty;
  OrderItem({required this.name, required this.qty});
  Map<String, dynamic> toJson() => {'name': name, 'qty': qty};
  factory OrderItem.fromJson(Map<String, dynamic> j) =>
      OrderItem(name: j['name'] ?? '', qty: (j['qty'] as num?)?.toInt() ?? 1);
}

class Order {
  final String id, userId, userName, userRole, date;
  final List<OrderItem> items;
  String status;
  double total;
  double points;
  double stored;
  String invoiceNo;
  Order({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.date,
    required this.items,
    this.status = 'pending',
    this.total = 0,
    this.points = 0,
    this.stored = 0,
    this.invoiceNo = '',
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userRole': userRole,
        'date': date,
        'items': items.map((e) => e.toJson()).toList(),
        'status': status,
        'total': total,
        'points': points,
        'stored': stored,
        'invoiceNo': invoiceNo,
      };
  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] ?? '',
        userId: j['userId'] ?? '',
        userName: j['userName'] ?? '',
        userRole: j['userRole'] ?? '',
        date: j['date'] ?? '',
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        status: j['status'] ?? 'pending',
        total: (j['total'] as num?)?.toDouble() ?? 0,
        points: (j['points'] as num?)?.toDouble() ?? 0,
        stored: (j['stored'] as num?)?.toDouble() ?? 0,
        invoiceNo: j['invoiceNo'] ?? '',
      );
}

class OrdersService {
  static Future<void> _putJson(String path, dynamic data) async {
    final r = await http.post(
      Uri.parse(kWriteProxy),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'path': path,
        'content': base64Encode(utf8.encode(jsonEncode(data))),
      }),
    );
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('PUT ${r.statusCode}');
    }
  }

  static Future<dynamic> _fetchJson(String path) async {
    try {
      final r = await http
          .get(Uri.parse(
              '$_raw/$path?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (_) {}
    try {
      final r = await http
          .get(Uri.parse(
              '$_site/assets/$path?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (_) {}
    return [];
  }

  static Future<List<CartItem>> loadCart(String uid) async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString('cart_$uid');
      if (s == null || s.isEmpty) return [];
      final List<dynamic> l = jsonDecode(s) as List<dynamic>;
      return l.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCart(String uid, List<CartItem> items) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'cart_$uid', jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<void> clearCart(String uid) async {
    final p = await SharedPreferences.getInstance();
    await p.remove('cart_$uid');
  }

  /// ✅ إضافة مركزية متسلسلة: قراءة حديثة + كتابة مؤمّنة ضد التعارض
  static Future<void> _cartChain = Future<void>.value();
  static Future<void> addToCart(String uid, String id, String name,
      String image, String brand, int qty) async {
    _cartChain = _cartChain.then((_) async {
      final cart = await loadCart(uid);
      final exist = cart.where((c) => c.id == id).toList();
      if (exist.isNotEmpty) {
        exist.first.qty += qty;
      } else {
        cart.add(CartItem(
            id: id, name: name, image: image, brand: brand, qty: qty));
      }
      await saveCart(uid, cart);
    });
    await _cartChain;
  }

  // ====================================================
  // 🚀 طبقة محلية: إخفاء/تحديث فوري قبل وصول السيرفر
  // ====================================================
  static const String _kTombKey = 'orders_tombstones';
  static const String _kStatusKey = 'orders_status_override';

  static Future<Map<String, int>> _loadTombs() async {
    final p = await SharedPreferences.getInstance();
    final m = <String, int>{};
    for (final e in (p.getStringList(_kTombKey) ?? [])) {
      final i = e.lastIndexOf('|');
      if (i > 0) {
        m[e.substring(0, i)] = int.tryParse(e.substring(i + 1)) ?? 0;
      }
    }
    return m;
  }

  static Future<void> _saveTombs(Map<String, int> m) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    m.removeWhere((_, exp) => exp < now);
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
        _kTombKey, m.entries.map((e) => '${e.key}|${e.value}').toList());
  }

  static Future<void> _markTomb(String id) async {
    final m = await _loadTombs();
    m[id] = DateTime.now().millisecondsSinceEpoch + 86400000;
    await _saveTombs(m);
  }

  static Future<Map<String, String>> _loadOverrides() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kStatusKey);
    if (s == null || s.isEmpty) return {};
    try {
      return Map<String, String>.from(jsonDecode(s) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveOverrides(Map<String, String> m) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kStatusKey, jsonEncode(m));
  }

  static Future<void> _saveOverride(String id, String status) async {
    final m = await _loadOverrides();
    m[id] = status;
    await _saveOverrides(m);
  }

  static Future<List<Order>> loadOrders() async {
    final d = await _fetchJson(kOrdersPath);
    List<Order> list = [];
    if (d is List) {
      list = d.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    }
    try {
      // ✅ إخفاء المحذوف محلياً + تنظيف السجل عند تطابق السيرفر
      final tombs = await _loadTombs();
      if (tombs.isNotEmpty) {
        final serverIds = list.map((o) => o.id).toSet();
        tombs.removeWhere((id, _) => !serverIds.contains(id));
        await _saveTombs(tombs);
        list.removeWhere((o) => tombs.containsKey(o.id));
      }
      // ✅ تطبيق الحالة المحلية فوراً + مسحها عند لحاق السيرفر
      final ov = await _loadOverrides();
      if (ov.isNotEmpty) {
        bool changed = false;
        for (final o in list) {
          final st = ov[o.id];
          if (st != null) {
            if (o.status == st) {
              ov.remove(o.id);
              changed = true;
            } else {
              o.status = st;
            }
          }
        }
        if (changed) await _saveOverrides(ov);
      }
    } catch (_) {}
    return list;
  }

  static Future<void> submitOrder(Order o) async {
    final list = await loadOrders();
    list.add(o);
    await _putJson(kOrdersPath, list.map((e) => e.toJson()).toList());
  }

  static Future<void> updateOrder(Order o) async {
    await _saveOverride(o.id, o.status); // ✅ الحالة تتحدث فوراً محلياً
    final list = await loadOrders();
    final i = list.indexWhere((x) => x.id == o.id);
    if (i >= 0) list[i] = o;
    await _putJson(kOrdersPath, list.map((e) => e.toJson()).toList());
  }

  static Future<void> deleteOrder(String id) async {
    await _markTomb(id); // ✅ إخفاء فوري محلياً قبل إرسال الحذف
    final list = await loadOrders();
    list.removeWhere((x) => x.id == id);
    await _putJson(kOrdersPath, list.map((e) => e.toJson()).toList());
  }

  // ====================================================
  // 🗑 Tombstones للفواتير/المرتجعات: إخفاء فوري + حذف بالخلفية
  // ====================================================
  static const String _kInvTombKey = 'inv_tombstones';
  static const String _kRetTombKey = 'ret_tombstones';

  static Future<Set<String>> _loadSet(String key) async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(key) ?? []).toSet();
  }

  static Future<void> _saveSet(String key, Set<String> v) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(key, v.toList());
  }

  static Future<void> markInvoiceDeleted(String id) async {
    final s = await _loadSet(_kInvTombKey);
    s.add(id);
    await _saveSet(_kInvTombKey, s);
  }

  static Future<void> markReturnDeleted(String id) async {
    final s = await _loadSet(_kRetTombKey);
    s.add(id);
    await _saveSet(_kRetTombKey, s);
  }

  static Future<List<Invoice>> loadInvoicesFiltered() async {
    final list = await StoreService.loadInvoices();
    final tombs = await _loadSet(_kInvTombKey);
    if (tombs.isNotEmpty) {
      final ids = list.map((e) => e.id).toSet();
      tombs.removeWhere((id) => !ids.contains(id));
      await _saveSet(_kInvTombKey, tombs);
      list.removeWhere((e) => tombs.contains(e.id));
    }
    return list;
  }

  static Future<List<Map<String, dynamic>>> loadReturnsFiltered() async {
    final list = await loadReturns();
    final tombs = await _loadSet(_kRetTombKey);
    if (tombs.isNotEmpty) {
      final ids = list.map((e) => '${e['id']}').toSet();
      tombs.removeWhere((id) => !ids.contains(id));
      await _saveSet(_kRetTombKey, tombs);
      list.removeWhere((e) => tombs.contains('${e['id']}'));
    }
    return list;
  }

  /// ✅ هل توجد عملية لم تصل للسيرفر بعد؟ (حذف/حالة معلّقة محلياً)
  static Future<bool> hasPendingSync() async {
    final ov = await _loadOverrides();
    if (ov.isNotEmpty) return true;
    final tombs = await _loadTombs();
    return tombs.isNotEmpty;
  }

  /// ✅ إعادة احتساب نقاط/رصيد مستخدم من صافي المشتريات (شراء − مرتجع)
  static Future<void> recalcUserTotals(String userId) async {
    final invs = await _fetchJson('assets/data/invoices.json');
    if (invs is! List) return;
    int sales = 0;
    int rets = 0;
    for (final i in invs) {
      if (i is Map && i['userId'] == userId) {
        if (i['type'] == 'sale') {
          sales += ((i['total'] as num?)?.toInt() ?? 0);
        } else if (i['type'] == 'return') {
          rets += ((i['total'] as num?)?.toInt() ?? 0).abs();
        }
      }
    }
    final retList = await loadReturns();
    for (final r in retList) {
      if (r['userId'] == userId) {
        rets += ((r['total'] as num?)?.toInt() ?? 0).abs();
      }
    }
    final net = (sales - rets).clamp(0, 999999999);
    final pts = net ~/ kPointUnit;
    final st = net % kPointUnit;
    final users = await _fetchJson('assets/data/users.json');
    if (users is List) {
      bool ch = false;
      for (final u in users) {
        if (u is Map && u['id'] == userId) {
          u['points'] = pts;
          u['stored'] = st;
          ch = true;
        }
      }
      if (ch) await _putJson('assets/data/users.json', users);
    }
  }

  static Future<List<Map<String, dynamic>>> loadReturns() async {
    final d = await _fetchJson('assets/data/returns.json');
    if (d is List) {
      return d.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  static Future<void> deleteInvoice(String id) async {
    final invs = await _fetchJson('assets/data/invoices.json');
    String uid = '';
    if (invs is List) {
      for (final i in invs) {
        if (i is Map && i['id'] == id) {
          uid = '${i['userId'] ?? ''}';
          break;
        }
      }
      invs.removeWhere((i) => i is Map && i['id'] == id);
      await _putJson('assets/data/invoices.json', invs);
    }
    final rets = await loadReturns();
    if (rets.isNotEmpty) {
      rets.removeWhere((r) => r['orderId'] == id);
      await _putJson('assets/data/returns.json', rets);
    }
    if (uid.isNotEmpty) await recalcUserTotals(uid);
  }

  static Future<void> deleteReturn(String id) async {
    final rets = await loadReturns();
    String uid = '';
    for (final r in rets) {
      if (r['id'] == id) {
        uid = '${r['userId'] ?? ''}';
        break;
      }
    }
    rets.removeWhere((r) => r['id'] == id);
    await _putJson('assets/data/returns.json', rets);
    if (uid.isNotEmpty) await recalcUserTotals(uid);
  }

  static Future<void> deleteUserAll(String userId) async {
    final users = await _fetchJson('assets/data/users.json');
    if (users is List) {
      users.removeWhere((u) => u is Map && u['id'] == userId);
      await _putJson('assets/data/users.json', users);
    }
    final invs = await _fetchJson('assets/data/invoices.json');
    if (invs is List) {
      invs.removeWhere((i) => i is Map && i['userId'] == userId);
      await _putJson('assets/data/invoices.json', invs);
    }
    final rets = await _fetchJson('assets/data/returns.json');
    if (rets is List) {
      rets.removeWhere((r) => r is Map && r['userId'] == userId);
      await _putJson('assets/data/returns.json', rets);
    }
    final orders = await loadOrders();
    orders.removeWhere((o) => o.userId == userId);
    await _putJson(kOrdersPath, orders.map((e) => e.toJson()).toList());
  }

  static Future<void> patchUser(
      String id, Map<String, dynamic> patch) async {
    final users = await _fetchJson('assets/data/users.json');
    if (users is List) {
      final i = users.indexWhere((u) => u is Map && u['id'] == id);
      if (i >= 0) {
        final m = Map<String, dynamic>.from(users[i] as Map);
        m.addAll(patch);
        users[i] = m;
        await _putJson('assets/data/users.json', users);
      }
    }
  }

  static Future<void> addUserRaw(Map<String, dynamic> entry) async {
    final users = await _fetchJson('assets/data/users.json');
    if (users is List) {
      users.add(entry);
      await _putJson('assets/data/users.json', users);
    } else {
      await _putJson('assets/data/users.json', [entry]);
    }
  }

  static Future<void> acceptOrder(Order o) async {
    o.points = (o.total ~/ kPointUnit).toDouble();
    o.stored = (o.total % kPointUnit).toDouble();
    o.status = 'accepted';
    await updateOrder(o);

    final invs = await _fetchJson('assets/data/invoices.json');
    if (invs is List) {
      invs.add({
        'id': o.id,
        'userId': o.userId,
        'date': o.date,
        'type': 'sale',
        'no': o.invoiceNo,
        'total': o.total,
        'points': o.points.toInt(),
        'stored': o.stored.toInt(),
        'items': o.items
            .map((e) => {'name': e.name, 'price': 0, 'qty': e.qty})
            .toList(),
      });
      await _putJson('assets/data/invoices.json', invs);
    }

    final users = await _fetchJson('assets/data/users.json');
    if (users is List) {
      bool matched = false;
      for (final u in users) {
        if (u is Map &&
            (u['id']?.toString().trim() == o.userId ||
                u['name']?.toString().trim() == o.userName.trim())) {
          u['points'] =
              ((u['points'] as num?)?.toInt() ?? 0) + o.points.toInt();
          u['stored'] =
              ((u['stored'] as num?)?.toInt() ?? 0) + o.stored.toInt();
          matched = true;
        }
      }
      if (matched) await _putJson('assets/data/users.json', users);
    }

    await recalcUserTotals(o.userId);
  }

  static Future<void> rejectOrder(Order o) async {
    o.status = 'rejected';
    await updateOrder(o);
  }

  static Future<void> markReturned(
    Order o, {
    List<OrderItem>? returnedItems,
    double? customTotal,
    String? customInvoiceNo,
  }) async {
    final items = returnedItems ?? o.items;
    final total = customTotal ?? o.total;
    final invNo = customInvoiceNo ?? '';
    final pts = (total ~/ kPointUnit).toInt();
    final st = (total % kPointUnit).toInt();

    final invs = await _fetchJson('assets/data/invoices.json');
    if (invs is List) {
      final idx = invs.indexWhere(
          (i) => i is Map && i['id'] == o.id && i['type'] == 'sale');
      if (idx >= 0) {
        final sale = Map<String, dynamic>.from(invs[idx] as Map);
        final saleItems = List<Map<String, dynamic>>.from(
            (sale['items'] as List? ?? [])
                .map((e) => Map<String, dynamic>.from(e as Map)));
        for (final ret in items) {
          final match =
              saleItems.where((si) => si['name'] == ret.name).toList();
          if (match.isNotEmpty) {
            match.first['qty'] =
                ((match.first['qty'] as num?)?.toInt() ?? 0) - ret.qty;
          }
        }
        saleItems.removeWhere(
            (si) => ((si['qty'] as num?)?.toInt() ?? 0) <= 0);
        final oldTotal = ((sale['total'] as num?)?.toDouble() ?? 0);
        final newTotal =
            (oldTotal - total).clamp(0.0, double.infinity).toInt();
        sale['items'] = saleItems;
        sale['total'] = newTotal;
        sale['points'] = newTotal ~/ kPointUnit;
        sale['stored'] = newTotal % kPointUnit;
        invs[idx] = sale;
        await _putJson('assets/data/invoices.json', invs);
      }
    }

    final rets = await loadReturns();
    rets.add({
      'id': '${o.id}_ret_${DateTime.now().millisecondsSinceEpoch}',
      'orderId': o.id,
      'userId': o.userId,
      'date': DateTime.now().toString().substring(0, 10),
      'no': invNo,
      'purchaseNo': o.invoiceNo,
      'total': total.toInt(),
      'points': pts,
      'stored': st,
      'items': items
          .map((e) => {'name': e.name, 'qty': e.qty})
          .toList(),
    });
    await _putJson('assets/data/returns.json', rets);
    await recalcUserTotals(o.userId);
  }

  static Future<bool> convertStoredToPoints(String userId) async {
    final invs = await _fetchJson('assets/data/invoices.json');
    if (invs is! List) return false;
    int net = 0;
    int existing = 0;
    for (final i in invs) {
      if (i is Map && i['userId'] == userId) {
        net += ((i['stored'] as num?)?.toInt() ?? 0);
        if (i['type'] == 'stored_point') existing++;
      }
    }
    final rets = await loadReturns();
    for (final r in rets) {
      if (r['userId'] == userId) {
        net -= ((r['stored'] as num?)?.toInt() ?? 0);
      }
    }
    final gross = net + existing * kPointUnit;
    final times = gross ~/ kPointUnit;
    if (times <= existing) return false;
    for (int k = existing; k < times; k++) {
      invs.add({
        'id': '${userId}_sp_$k',
        'userId': userId,
        'date': DateTime.now().toString().substring(0, 10),
        'type': 'stored_point',
        'no': 'SP-${k + 1}',
        'total': kPointUnit,
        'points': 1,
        'stored': -kPointUnit,
        'items': const [],
      });
    }
    await _putJson('assets/data/invoices.json', invs);
    return true;
  }
}
