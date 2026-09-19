import 'dart:convert';
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';
import 'orders_service.dart';

/// 📴 خدمة العمل بدون إنترنت: كشف الاتصال + طابور الطلبات المحلية
class OfflineService {
  static bool _listenersAttached = false;
  static final List<void Function(bool)> _listeners = [];

  /// هل المتصفح متصل الآن؟
  static bool get isOnline => html.window.navigator.onLine;

  static void addListener(void Function(bool online) cb) {
    _listeners.add(cb);
  }

  /// ✅ تُستدعى مرة واحدة في main()
  static void init() {
    if (_listenersAttached) return;
    _listenersAttached = true;
    html.window.addEventListener('online', (_) => _notify(true));
    html.window.addEventListener('offline', (_) => _notify(false));
  }

  static void _notify(bool online) {
    for (final cb in List<void Function(bool)>.of(_listeners)) {
      cb(online);
    }
  }

  // ---------- طابور الطلبات المعلّقة ----------

  static Future<List<Order>> loadQueue() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('pending_orders');
    if (s == null || s.isEmpty) return [];
    try {
      final l = jsonDecode(s) as List<dynamic>;
      return l
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveQueue(List<Order> q) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'pending_orders', jsonEncode(q.map((e) => e.toJson()).toList()));
  }

  /// ➕ تعليق طلب محلياً (بدون إنترنت)
  static Future<void> enqueueOrder(Order o) async {
    final q = await loadQueue();
    q.add(o);
    await _saveQueue(q);
  }

  /// 📤 إرسال كل المعلّقات عند توفر النت — يعيد عدد المُرسل
  static Future<int> flushQueue() async {
    if (!isOnline) return 0;
    final q = await loadQueue();
    if (q.isEmpty) return 0;
    int sent = 0;
    final remaining = <Order>[];
    for (final o in q) {
      try {
        await OrdersService.submitOrder(o);
        sent++;
      } catch (_) {
        remaining.add(o);
      }
    }
    await _saveQueue(remaining);
    return sent;
  }
}
