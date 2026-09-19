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

    await convertStoredToPoints(o.userId);
  }

  static Future<void> rejectOrder(Order o) async {
    o.status = 'rejected';
    await updateOrder(o);
  }

  /// 🔁 مرتجع: لا يغيّر حالة الفاتورة (تبقى مقبولة) — يسجّل مرتجعاً مرتبطاً بها
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
      invs.add({
        'id': '${o.id}_ret_${DateTime.now().millisecondsSinceEpoch}',
        'userId': o.userId,
        'date': DateTime.now().toString().substring(0, 10),
        'type': 'return',
        'no': invNo,
        'total': -(total.toInt()),
        'points': -pts,
        'stored': -st,
        'orderId': o.id,
        'items': items
            .map((e) => {'name': e.name, 'price': 0, 'qty': e.qty})
            .toList(),
      });
      await _putJson('assets/data/invoices.json', invs);
    }
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
