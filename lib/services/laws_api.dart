import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eduvial/config/constants.dart';

class LawsApi {
  static Map<String, String> _headers() => ApiConstants.authHeader();

  // ---------- Public API ----------

  // GET /api/laws
  static Future<List<Map<String, dynamic>>> getAll() async {
    final r = await http
        .get(Uri.parse(ApiConstants.lawsEndpoint), headers: _headers())
        .timeout(const Duration(seconds: 12));
    _check(r);
    return _dedupAndClean(_asListOrSingle(jsonDecode(r.body)));
  }

  // GET /api/laws/categories
  static Future<List<String>> getCategories() async {
    final r = await http
        .get(Uri.parse(ApiConstants.lawsCategoriesEndpoint), headers: _headers())
        .timeout(const Duration(seconds: 12));
    _check(r);
    final data = jsonDecode(r.body);
    if (data is List) return data.map((e) => e.toString()).toList();
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).map((e) => e.toString()).toList();
    }
    return const [];
  }

  // GET /api/laws/category/{name}
  static Future<List<Map<String, dynamic>>> getByCategory(String category) async {
    final r = await http
        .get(ApiConstants.lawsByCategory(category), headers: _headers())
        .timeout(const Duration(seconds: 12));

    if (r.statusCode == 404) {
      // No results → lista vacía (no error)
      return <Map<String, dynamic>>[];
    }
    _check(r);
    return _dedupAndClean(_asListOrSingle(jsonDecode(r.body)));
  }

  // GET /api/laws/filter?article=145   (compat)
  static Future<List<Map<String, dynamic>>> filterByArticle(String article) =>
      filter(article: article);

  /// GET /api/laws/filter?search=... | ?article=... | ?title=... | ?sanc=...
  static Future<List<Map<String, dynamic>>> filter({
    String? search,
    String? article,
    String? title,
    String? sanc,
  }) async {
    final qp = <String, String>{};
    if (search?.trim().isNotEmpty == true) qp['search'] = search!.trim();
    if (article?.trim().isNotEmpty == true) qp['article'] = article!.trim();
    if (title?.trim().isNotEmpty == true) qp['title'] = title!.trim();
    if (sanc?.trim().isNotEmpty == true) qp['sanc'] = sanc!.trim();

    final uri = Uri.parse('${ApiConstants.lawsEndpoint}/filter')
        .replace(queryParameters: qp.isEmpty ? null : qp);

    final r = await http.get(uri, headers: _headers())
        .timeout(const Duration(seconds: 12));

    if (r.statusCode == 404) {
      // No results → lista vacía (no error)
      return <Map<String, dynamic>>[];
    }
    _check(r);

    final decoded = jsonDecode(r.body);
    final list = _asListOrSingle(decoded);
    return _dedupAndClean(list);
  }

  // GET /api/laws/filters/info
  static Future<Map<String, dynamic>> getFiltersInfo() async {
    final r = await http
        .get(Uri.parse(ApiConstants.lawsFiltersInfoEndpoint), headers: _headers())
        .timeout(const Duration(seconds: 12));
    _check(r);
    final data = jsonDecode(r.body);
    return data is Map ? data.cast<String, dynamic>() : {'raw': data};
  }

  // ---------- helpers ----------

  static void _check(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      final bodyPreview =
      r.body.length > 200 ? '${r.body.substring(0, 200)}…' : r.body;
      throw Exception('HTTP ${r.statusCode}: $bodyPreview');
    }
  }

  /// Acepta:
  ///   [ ... ],
  ///   { data:[...] } o { items:[...] },
  ///   { ...objeto... } (lo envuelve en lista)
  static List<Map<String, dynamic>> _asListOrSingle(dynamic data) {
    final List list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['items'] is List) {
      list = data['items'];
    } else if (data is Map && data['data'] is List) {
      list = data['data'];
    } else if (data is Map) {
      list = [data]; // normaliza objeto único -> lista
    } else {
      list = const <dynamic>[];
    }
    return list.cast<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  /// Quita duplicados por 'id' y limpia campos de texto
  static List<Map<String, dynamic>> _dedupAndClean(List<Map<String, dynamic>> raw) {
    final byId = <int, Map<String, dynamic>>{};
    for (final m in raw) {
      final id = (m['id'] as num?)?.toInt();
      if (id == null) continue;

      final cleaned = Map<String, dynamic>.from(m);
      if (cleaned['description'] is String) {
        cleaned['description'] = _cleanText(cleaned['description'] as String);
      }
      if (cleaned['sanction'] is String) {
        final s = _cleanText(cleaned['sanction'] as String).trim();
        cleaned['sanction'] = s.isEmpty ? null : s;
      }
      if (cleaned['categories'] is List) {
        cleaned['categories'] =
            (cleaned['categories'] as List).map((e) => e.toString()).toList();
      }

      byId[id] = cleaned; // sobrescribe si llega duplicado
    }
    return byId.values.toList();
  }

  static String _cleanText(String s) => s
      .replaceAll(r'\r\n', '\n') // por si viene doble escapado
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
