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
  final s = n.toStringAsFixed(0);
  final out = StringBuffer();
  int c = 0;
  for (int i = s.length - 1; i >= 0; i--) {
    out.write(s[i]);
    c++;
    if (c % 3 == 0 && i != 0) out.write(',');
  }
  return out.toString().split('').reversed.join();
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
  String origId;
  String note;
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
    this.origId = '',
    this.note = '',
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
        if (origId.isNotEmpty) 'origId': origId,
        if (note.isNotEmpty) 'note': note,
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
        origId: j['origId'] ?? '',
        note: j['note'] ?? '',
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
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (_) {}
    try {
      final r = await http
          .get(Uri.parse(
              '$_site/assets/$path?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 8));
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

  static Future<List<Order>> loadOrders() async {
    final d = await _fetchJson(kOrdersPath);
    if (d is List) {
      return d.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<void> submitOrder(Order o) async {
    final list = await loadOrders();
    list.add(o);
    await _putJson(kOrdersPath, list.map((e) => e.toJson()).toList());
  }

  static Future<void> updateOrder(Order o) async {
    final list = await loadOrders();
    final i = list.indexWhere((x) => x.id == o.id);
    if (i >= 0) list[i] = o;
    await _putJson(kOrdersPath, list.map((e) => e.toJson()).toList());
  }

  static Future<void> deleteOrder(String id) async {
    final list = await loadOrders();
    list.removeWhere((x) => x.id == id);
    await _putJson(kOrdersPath, list.map((e) => e.toJson()).toList());
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
  }

  static Future<void> acceptReturn(Order o) async {
    o.status = 'return_accepted';
    o.note = 'تم تعديل القيم والمكافأة بعد المرتجع';
    await updateOrder(o);
    final invs = await _fetchJson('assets/data/invoices.json');
    if (invs is List) {
      invs.add({
        'id': o.id,
        'userId': o.userId,
        'date': o.date,
        'type': 'return',
        'no': o.invoiceNo,
        'total': o.total,
        'points': 0,
        'stored': 0,
        'items': o.items
            .map((e) => {'name': e.name, 'price': 0, 'qty': e.qty})
            .toList(),
        'note': 'فاتورة مرتجع',
      });
      for (final inv in invs) {
        if (inv is Map && inv['id']?.toString() == o.origId) {
          final List<dynamic> items = List<dynamic>.from(inv['items'] ?? []);
          for (final ret in o.items) {
            for (final it in items) {
              if (it is Map && it['name']?.toString() == ret.name) {
                it['qty'] = ((it['qty'] as num?)?.toInt() ?? 0) - ret.qty;
              }
            }
          }
          items.removeWhere(
              (it) => it is Map && ((it['qty'] as num?)?.toInt() ?? 0) <= 0);
          final oldTotal = (inv['total'] as num?)?.toDouble() ?? 0;
          final newTotal = oldTotal - o.total;
          inv['items'] = items;
          inv['total'] = newTotal;
          inv['points'] = (newTotal ~/ kPointUnit).toInt();
          inv['stored'] = (newTotal % kPointUnit).toInt();
          inv['note'] = 'تم تعديل القيم والمكافأة بعد المرتجع';
        }
      }
      await _putJson('assets/data/invoices.json', invs);
    }
  }

  static Future<void> rejectOrder(Order o) async {
    await deleteOrder(o.id);
  }

  /// ✅ 1/3 — تُستدعى دورياً من AppSettings لتحويل الرصيد المتبقي المتراكم إلى نقاط
  static Future<bool> convertStoredToPoints(String userId) async {
    try {
      final invs = await _fetchJson('assets/data/invoices.json');
      if (invs is! List) return false;

      int totalStored = 0;
      for (final inv in invs) {
        if (inv is Map &&
            inv['userId']?.toString() == userId &&
            inv['type']?.toString() == 'sale' &&
            inv['converted']?.toString() != 'true') {
          totalStored += ((inv['stored'] as num?)?.toInt() ?? 0);
        }
      }

      if (totalStored >= kPointUnit) {
        final newPoints = totalStored ~/ kPointUnit;
        final remaining = totalStored % kPointUnit;

        bool marked = false;
        for (final inv in invs) {
          if (inv is Map &&
              inv['userId']?.toString() == userId &&
              inv['type']?.toString() == 'sale' &&
              inv['converted']?.toString() != 'true') {
            inv['stored'] = 0;
            inv['converted'] = true;
            marked = true;
          }
        }
        // أعد المتبقي إلى آخر فاتورة
        if (marked) {
          for (int i = invs.length - 1; i >= 0; i--) {
            final inv = invs[i];
            if (inv is Map &&
                inv['userId']?.toString() == userId &&
                inv['type']?.toString() == 'sale') {
              inv['stored'] = remaining;
              break;
            }
          }
        }

        final users = await _fetchJson('assets/data/users.json');
        if (users is List) {
          for (final u in users) {
            if (u is Map && u['id']?.toString() == userId) {
              u['points'] = ((u['points'] as num?)?.toInt() ?? 0) + newPoints;
              u['stored'] = remaining;
            }
          }
          await _putJson('assets/data/users.json', users);
        }
        await _putJson('assets/data/invoices.json', invs);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// ✅ 2/3 — تجمع النقاط والرصيد من قائمة فواتير لمستخدم معين
  static Map<String, int> returnPoolOf(List<dynamic> invs, String uid) {
    int pts = 0;
    int st = 0;
    for (final i in invs) {
      if (i is Map && i['userId']?.toString() == uid) {
        pts += ((i['points'] as num?)?.toInt() ?? 0);
        st += ((i['stored'] as num?)?.toInt() ?? 0);
      }
    }
    return {'points': pts, 'stored': st};
  }

  /// ✅ 3/3 — تعليم الطلب كمرتجع مقبول مع تعبئة السعر والرقم
  static Future<void> markReturned(Order o, double total, String invoiceNo) async {
    o.total = total;
    o.invoiceNo = invoiceNo;
    await acceptReturn(o);
  }
}
