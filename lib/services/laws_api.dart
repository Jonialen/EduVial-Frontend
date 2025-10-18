import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eduvial/config/constants.dart';

class LawsApi {
  // Usa tu helper de headers (Authorization, etc.)
  static Map<String, String> _headers() => ApiConstants.authHeader();

  // GET /api/laws
  static Future<List<Map<String, dynamic>>> getAll() async {
    final r = await http.get(
      Uri.parse(ApiConstants.lawsEndpoint),
      headers: _headers(),
    );
    _check(r);
    return _asList(jsonDecode(r.body));
  }

  // GET /api/laws/categories
  static Future<List<String>> getCategories() async {
    final r = await http.get(
      Uri.parse(ApiConstants.lawsCategoriesEndpoint),
      headers: _headers(),
    );
    _check(r);

    final data = jsonDecode(r.body);
    if (data is List) return data.map((e) => e.toString()).toList();
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).map((e) => e.toString()).toList();
    }
    return [];
  }

  // GET /api/laws/category/{name}
  static Future<List<Map<String, dynamic>>> getByCategory(String category) async {
    final r = await http.get(
      ApiConstants.lawsByCategory(category), // <-- usa helper de ApiConstants
      headers: _headers(),
    );
    _check(r);
    return _asList(jsonDecode(r.body));
  }

  // GET /api/laws/filter?article=145
  static Future<List<Map<String, dynamic>>> filterByArticle(String article) async {
    final r = await http.get(
      ApiConstants.lawsFilterByArticle(article: article),
      headers: _headers(),
    );
    _check(r);
    return _asList(jsonDecode(r.body));
  }

  // GET /api/laws/filters/info
  static Future<Map<String, dynamic>> getFiltersInfo() async {
    final r = await http.get(
      Uri.parse(ApiConstants.lawsFiltersInfoEndpoint),
      headers: _headers(),
    );
    _check(r);

    final data = jsonDecode(r.body);
    return data is Map ? data.cast<String, dynamic>() : {'raw': data};
  }

  // ---------- helpers ----------
  static void _check(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('HTTP ${r.statusCode}');
    }
  }

  /// Acepta `[ ... ]`, `{ data:[...] }` o `{ items:[...] }`
  static List<Map<String, dynamic>> _asList(dynamic data) {
    final List list =
    (data is List)
        ? data
        : (data is Map && data['items'] is List)
        ? data['items']
        : (data is Map && data['data'] is List)
        ? data['data']
        : <dynamic>[];
    return list.cast<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
}
