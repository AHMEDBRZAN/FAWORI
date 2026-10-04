import 'dart:convert';

import 'package:http/http.dart' as http;

/// ✅ خدمة الفواتير التاريخية (من imported_invoices.json)
class ImportService {
  static const String _raw =
      'https://raw.githubusercontent.com/AHMEDBRZAN/FAWORI/main';

  static List<Map<String, dynamic>>? _cache;
  static Map<String, List<Map<String, dynamic>>>? _byCustomer;

  /// ✅ تطبيع الاسم: إزالة الأرقام والرموز والمسافات الزائدة
  static String normalizeName(String n) {
    var s = n.replaceAll(RegExp(r'[0-9]+'), ' ');
    s = s.replaceAll(RegExp(r'[\\/|•\-.(),]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// ✅ قراءة الملف مرة واحدة مع كاش + فهرسة حسب العميل
  static Future<List<Map<String, dynamic>>> loadImported() async {
    if (_cache != null) return _cache!;
    try {
      final r = await http
          .get(Uri.parse(
              '$_raw/assets/data/imported_invoices.json?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 25));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body);
        final list = (j['invoices'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _cache = list;
        final m = <String, List<Map<String, dynamic>>>{};
        for (final inv in list) {
          final key = normalizeName('${inv['customer_name'] ?? ''}');
          if (key.isEmpty) continue;
          m.putIfAbsent(key, () => []).add(inv);
        }
        _byCustomer = m;
        return list;
      }
    } catch (_) {}
    _cache = [];
    _byCustomer = {};
    return [];
  }

  /// ✅ فواتير عميل بالاسم (مطابقة بعد التطبيع + مطابقة جزئية احتياطية)
  static Future<List<Map<String, dynamic>>> historyFor(
      String userName) async {
    await loadImported();
    final key = normalizeName(userName);
    if (key.isEmpty || _byCustomer == null) return const [];
    final exact = _byCustomer![key];
    if (exact != null && exact.isNotEmpty) return exact;
    for (final e in _byCustomer!.entries) {
      if (e.key.isNotEmpty &&
          (e.key.contains(key) || key.contains(e.key))) {
        return e.value;
      }
    }
    return const [];
  }

  /// ✅ صافي السجل التاريخي (موجب شراء / سالب مرتجع)
  static int historyNet(List<Map<String, dynamic>> hist) {
    double sum = 0;
    for (final h in hist) {
      sum += (h['total'] as num?)?.toDouble() ?? 0;
    }
    return sum.toInt();
  }
}
