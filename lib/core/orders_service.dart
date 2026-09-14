import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'store_service.dart';

/// 📡 قراءة حية مباشرة من المستودع
const String _raw = 'https://raw.githubusercontent.com/AHMEDBRZAN/FAWORI/main';
const String _site = 'https://ahmedbrzan.github.io/FAWORI';
const String kOrdersPath = 'assets/data/orders.json';
const int kPointUnit = 125000;

/// 🔐 وسيط الكتابة (Cloudflare Worker) — التوكن عنده وليس عندنا
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
  /// ✍️ كتابة عبر الوسيط — بدون أي توكن داخل التطبيق
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

  /// 📡 قراءة ذكية: مستودع مباشر ← ثم نسخة الموقع ← مع مهلة 8 ثوانٍ
  static Future<dynamic> _fetchJson(String path) async {
    // 1) مباشر من المستودع (الأحدث)
    try {
      final r = await http
          .get(Uri.parse(
              '$_raw/$path?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (_) {}
    // 2) احتياط: نسخة الموقع المبنية
    try {
      final r = await http
          .get(Uri.parse(
              '$_site/assets/$path?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (_) {}
    return [];
  }

  // ===== السلة (محلية محفوظة) =====
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

  // ===== الطلبات =====
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

  /// ✅ قبول: يحتسب النقاط/الرصيد، ينشر الفاتورة، يحدّث نقاط المستخدم
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
      for (final u in users) {
        if (u is Map && u['id'] == o.userId) {
          u['points'] = ((u['points'] as num?)?.toInt() ?? 0) + o.points.toInt();
          u['stored'] = ((u['stored'] as num?)?.toInt() ?? 0) + o.stored.toInt();
        }
      }
      await _putJson('assets/data/users.json', users);
    }
  }

  /// ❌ رفض: حذف الطلب نهائياً
  static Future<void> rejectOrder(Order o) async {
    await deleteOrder(o.id);
  }
}
